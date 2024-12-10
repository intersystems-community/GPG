# GPG Interoperability Adapter for InterSystems IRIS

For my hundredth article on the developer community, I wanted to present something practical, so here's a comprehensive implementation of the GPG Interoperability Adapter for InterSystems IRIS. 
Every so often, I would encounter a request for some GPG support, so I had several code samples written for a while, and the article contest moved me to combine all of them and add missing GPG functionality for a fairly complete coverage. That said, this Business Operation primarily covers data actions, skipping management actions such as key generation, export, and retrieval as they are usually one-off and performed manually anyways. However, this implementation does support key imports for obvious reasons. Well, let's get into it.

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

# Why Business Operation?

While writing this, I received a very interesting question about why GPG needs to be a separate Business Host and not a part of a Business Process. As this can be very important for any cryptography code, I wanted to include my rationale on that topic. 

I would like to start with how Business Processes work and why this is a crucial consideration for cryptography code.
Consider this simple Business Process `User.BPL`:

```xml
<process language='objectscript' request='Ens.Request' response='Ens.Response'>
  <context>
    <property name='x' type='%Integer' instantiate='0' />
  </context>
  <sequence>
    <assign property="context.x" value="1" action="set" />
    <if name='Check' condition='1' >
      <true>
        <assign property="context.x" value="2" action="set"  />
      </true>
    </if>
  </sequence>
</process>
```

It will generate the `Context` class with one property:

```objectscript
Class User.BPL.Context Extends Ens.BP.Context 
{
Property x As %Integer;
}
```

And `State` class with two methods (simplified):
```objectscript
Method S1(process As User.BPL, context As User.BPL.Context)
{
  Set context.x=1
  Set ..%NextState="S2"
  Quit ..ManageState()
}

Method S2(process As User.BPL, context As User.BPL.Context)
{
  Set context.x=2
  Set ..%NextState="S3"
  Quit ..ManageState()
}
```

Since BP is a state machine, it will simply call the first state and then whatever is set in `%NextState`. Each state has information on all possible next states—for example, one next state for a true path and another for a false path in the if block state. 
However, the BP engine manages the state between state invocations. In our case, it saves the `User.BPL.Context` object which holds an entire context - property `x`. 
But there's no guarantee that after saving the state of a particular BP invocation, the subsequent state for this invocation would be called next immediately. 
The BP engine might wait for a reply from BO/BP, work on another invocation, or even work on another process entirely if we're using shared pool workers. Even with a dedicated worker pool, another worker might grab the same process invocation to continue working on it.
This is usually fine since the worker's first action before executing the next state is loading the context from memory—in our example, it's an object of the `User.BPL.Context` class with one integer property `x`, which works.
But in the case of any cryptography library, the context must contain something along the lines of:

```objectscript
/// Private Python object holding GPG module
Property %GPG As %SYS.Python; 
```

Which is a runtime Python module object that cannot be persisted. It also likely cannot be pickled or even dilled as we initialize a crypto context to hold a key — the library is rather pointless without it, after all.

So, while theoretically, it could work if the entire cryptography workload (idempotent init – idempotent key load - encryption - signing) is handled within one state, that is a consideration that must always be carefully observed. Especially since, in many cases, it will work in low-load environments (i.e., dev) where there's no queue to speak of, and one BP invocation will likely progress from beginning to end uninterrupted. But when the same code is promoted to a high-load environment with queues and resource contention (i.e., live), the BP engine is likelier to switch between different invocations to speed things up.

That's why I highly recommend extracting your cryptography code into a separate business operation. Since one business operation can handle multiple message types, you can have one business operation that processes PGP signing/encryption/verification requests. Since BOs (and BSes) are not state machines, once you load the library and key(s) in the init code, they will not be unloaded until your BH job expires one way or another.

# Conclusion

GPG Interoperability Adapter for InterSystems IRIS allows you to use GPG easily if you need Encryption/Decryption and Signing/Verification.

# Documentation
- [GnuPG](https://gnupg.org/)
- [Python GnuPG](https://gnupg.readthedocs.io/en/latest/)
- OpenExchange
