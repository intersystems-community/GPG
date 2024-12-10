# GPG
GPG Interoperability Adapter for InterSystems IRIS

[GnuPG](https://gnupg.org/) is a complete and free implementation of the OpenPGP standard as defined by RFC4880 (also known as PGP). GnuPG allows you to encrypt and sign your data and communications and perform the corresponding tasks of decryption and signature verification.

For InterSystems Interoperability adapter, I will be using Embedded Python and [gnupg](https://gnupg.readthedocs.io/en/latest/) Python library specifically.

> The gnupg module allows Python programs to make use of the functionality provided by the GNU Privacy Guard (abbreviated GPG or GnuPG). Using this module, Python programs can encrypt and decrypt data, digitally sign documents and verify digital signatures, manage (generate, list and delete) encryption keys, using Public Key Infrastructure (PKI) encryption technology based on OpenPGP.

# Disclaimer

This project, whenever possible, aims to use GPG defaults. Your organization's security policies might differ. Your jurisdiction or your organization's compliance with various security standards might require you to use GPG with different settings or configurations. The user is wholly responsible for verifying that cryptographic settings are adequate and fully compliant with all applicable regulations. This module is provided under an MIT license. Author and InterSystems are not responsible for any improper or incorrect use of this module. 

# Installation
1. First, we'll need to install `python-gnupg`, which can be done using `pip` or `irispip`:
```
irispip install  --target C:\InterSystems\IRIS\mgr\python python-gnupg
```

If you're on Windows, you should [install GPG itself](https://gnupg.org/download/index.html). GPG binaries must be in the path, and you must restart IRIS after GPG installation. If you're on Linux or Mac, you likely already have GPG installed. 

2. After that, load the code into any Interoperability-enabled namespace and compile it. The code is in `Utils.GPG` package and has the following classes:
- `Operation`: main Business Operation class
- `*Request`: Interoperability request classes
- `*Response`: Interoperability response classes
- `File*`: Interoperability request and response classes using %Stream.FileBinary for payload
- `Tests`: code for manual testing, samples

Each request has two properties: 
- `Stream` — set that to your payload. In File* requests, your stream must be of the `%Stream.FileBinary` class; for non-file requests, it must be of the `%Stream.GlobalBinary` class.
- `ResponseFilename` — (Optional) If set, the response will be written into a file at the specified location. If not set, for File requests, the response will be placed into a file with `.asc` or `.txt` added to the request filename. If not set, for global stream requests, the response will be a global stream.
The request type determines the GPG operation to perform. For example, `EncryptionRequest` is used to encrypt plaintext payloads. 

Each response (except for Verify) has a `Stream` property, which holds the response, and a `Result` property, which holds a serializable subset of a GPG result object converted into IRIS persistent object. The most important property of a `Result` object is a boolean `ok`, indicating overall success. 

3. Next, you need a sample key; skip this step if you already have one (this repo also contains sample keys, you can use them for debugging, passphrase is `123456`):

Use any Python shell (for example, `do $system.Python.Shell()`):

```python
import gnupg
gpg_home = 'C:\InterSystems\IRIS\Mgr\pgp'
gpg = gnupg.GPG(gnupghome=gpg_home)
input_data = gpg.gen_key_input(key_type="RSA", key_length=2048)
master_key = gpg.gen_key(input_data)
public_key = 'C:\InterSystems\IRIS\Mgr\keys\public.asc'
result_public = gpg.export_keys(master_key.fingerprint, output=public_key)
private_key = 'C:\InterSystems\IRIS\Mgr\keys\private.asc'
result_private = gpg.export_keys(master_key.fingerprint, True, passphrase="", output=private_key)
```

You must set `gpg_home`, `private_key`, and `public_key` to valid paths. Note that a private key can only be exported with a passphrase.

# Production configuration.

Add `Utils.GPG.Operation` to your Production, there are four custom settings available:
- `Home`: writable directory for GPG to keep track of an internal state.
- `Key`: path to a key file to import
- `Credentials`: if a key file is passphrase protected, select a Credential with a password to be used as a passphrase.
- `ReturnErrorOnNotOk`: If this is `False` and the GPG operation fails, the response will be returned with all the info we managed to collect. If this is `True`, any GPG error will result in an exception.

On startup, the operation loads the key and logs `GPG initialized` if everything is okay. After that, it can accept all request types based on an imported key (a public key can only encrypt and verify).

# Usage

Here's a sample encryption request:

```objectscript
/// do ##class(Utils.GPG.Tests).Encrypt()
ClassMethod Encrypt(target = {..#TARGET}, plainFilename As %String, encryptedFilename As %String)
{
	if $d(plainFilename) {
		set request = ##class(FileEncryptionRequest).%New()
		set request.Stream = ##class(%Stream.FileBinary).%New()
		$$$TOE(sc, request.Stream.LinkToFile(plainFilename))
	} else {
		set request = ##class(EncryptionRequest).%New()
		set request.Stream = ##class(%Stream.GlobalBinary).%New()
		do request.Stream.Write("123456")
		$$$TOE(sc, request.Stream.%Save())
	}
	
	if $d(encryptedFilename) {
		set request.ResponseFilename = encryptedFilename
	}
		
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest(target, request, .response, .sessionid)
	
	zw sc, response, sessionid
}
```
In the same manner, you can perform Decryption, Sign, and Verification requests. Check `Utils.GPG.Tests` for all the examples.
