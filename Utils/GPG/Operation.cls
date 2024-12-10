/// Performs four main GPG functions: Encrypt/Decrypt, Sign/Verify.
Class Utils.GPG.Operation Extends Ens.BusinessOperation
{

/// Directory for gnupg intermediary files
Property Home As %String(MAXLEN = 1000) [ Required ];

/// Path to a key 
Property Key As %String(MAXLEN = 1000) [ Required ];

/// This is the ID name of the set of credentials which hold the passphrase for a private key.
/// This is only required if you operate with a passphrase protected private key.
Property Credentials As %String;

/// Throw an exception if GPG result object ok property is false.
Property ReturnErrorOnNotOk As %Boolean [ InitialExpression = {$$$NO} ];

/// Private Python object holding GPG module
Property %GPG As %SYS.Python;

/// Private property holding key fingerprint
Property %Fingerprint As %VarString;

/// Helper function converting GPG result object into JSON
Property %ResultToJSON As %SYS.Python;

Parameter SETTINGS As %String = "Home:GPG,Key:GPG,Credentials:GPG:credentialsSelector,ReturnErrorOnNotOk:GPG";

/// Init GPG
Method OnInit() As %Status
{
    #Dim sc As %Status = $$$OK
    If '##class(%File).Exists(..Key) {
        Set sc = $$$ERROR($$$GeneralError, "Key is not set or does not exist.")
    } ElseIf '##class(%File).DirectoryExists(..Home) {
        Set sc = $$$ERROR($$$GeneralError, "Home is not set or does not exist.")
    } Else {
        Set ..%GPG = ..InitGPG(..Home)
        If $classname(..%GPG) '= ##class(%SYS.Python).%ClassName($$$YES) {
            Set sc = $$$ERROR($$$GeneralError, "Can't init GPG")
        } Else {
			If ..Credentials'="" {
			
				#; Try and open the named credentials object
				Set credentials=##class(Ens.Config.Credentials).%OpenId(..Credentials,,.sc)
				$$$TOE(sc, sc)
				
				#; Fill in the details
				Set passphrase = credentials.Password
			} Else {
				Set passphrase = ##class(%SYS.Python).None()
			}
	        
            Set ..%Fingerprint = ..LoadKey(..%GPG, ..Key, passphrase)
            $$$LOGINFO("GPG initialized")
        }
    }
	Quit sc
}

Method InitGPG(home As %String) As %SYS.Python [ Language = python ]
{
import gnupg
## this is where the keys will reside
gpg = gnupg.GPG(gnupghome=home)
gpg.encoding = 'utf-8'
return gpg
}

Method LoadKey(gpg As %SYS.Python, key As %String, passphrase As %String) As %String [ Language = python ]
{
import_result = gpg.import_keys_file(key, passphrase=passphrase)
fingerprint = import_result.results[0]["fingerprint"]
gpg.trust_keys(fingerprint, 'TRUST_ULTIMATE')
return fingerprint
}

Method Encrypt(request As EncryptionRequest, Output response As EncryptionResponse) As %Status
{
	#Dim sc As %Status = $$$OK

	Set isFileStream = ..IsFileStream(request.Stream)
    If request.ResponseFilename '= "" {
	    Set encryptedFilename = request.ResponseFilename
    } ElseIf isFileStream {
	    Set encryptedFilename = request.Stream.Filename _ ".asc"
    } Else {
	    Set encryptedFilename = ##class(%File).TempFilename("asc")
    }
    
    If isFileStream {
    	Set plainFilename = request.Stream.Filename
    } Else {
	    Set plainFilename = ##class(%File).TempFilename("txt")
	    Set plainStream = ##class(%Stream.FileCharacter).%New()
	    $$$TOE(sc, plainStream.LinkToFile(plainFilename))
	    $$$TOE(sc, plainStream.CopyFromAndSave(request.Stream))
	    Kill plainStream
    }
    Set result = ..EncryptPy(..%GPG, ..%Fingerprint, plainFilename, encryptedFilename)
   
    
    If isFileStream || (request.ResponseFilename '= "") {
	    Set response = ##class(FileEncryptionResponse).%New()
    } Else { 
		Set response = ##class(EncryptionResponse).%New()
    }
    
	Set response.Stream = $system.OBJ.New(request.Stream.%ClassName($$$YES))
	
	If isFileStream || (request.ResponseFilename '= "") {
		$$$TOE(sc, response.Stream.LinkToFile(encryptedFilename))
	} Else {
		Do ##class(%File).Delete(plainFilename)
	    Set encryptedStream = ##class(%Stream.FileCharacter).%New()
	    $$$TOE(sc, encryptedStream.LinkToFile(encryptedFilename))
	    $$$TOE(sc, response.Stream.CopyFromAndSave(encryptedStream))
	    Kill encryptedStream
	    Do ##class(%File).Delete(encryptedFilename)		
	}
	
    Set response.Result = ..ProcessResult(result)
    Do ..CheckResultObject(response.Result)
    
    Quit sc
}

/// Perform a check on a result object.
/// Throws an exception on error
Method CheckResultObject(result As Result)
{
	quit:'..ReturnErrorOnNotOk
	
	if result.ok = $$$NO {
		do result.%JSONExportToString(.json)
		throw ##class(%Exception.General).%New("<GPG>",,,json) 
	}
}

Method ProcessResult(result As %SYS.Python) As Result
{
	Set json = ..ResultToJSON(result)
	$$$LOGINFO(json)
	Set resultObj = ##class(Result).%New()
    $$$TOE(sc, resultObj.%JSONImport(json))
    quit resultObj
}

ClassMethod ResultToJSON(result As %SYS.Python) [ Language = python ]
{
import json
result_dict = {}
result_dict["data"] = result.data.decode("utf-8")
for prop in ['creation_date', 'expire_timestamp', 'fingerprint', 'key_id', 'key_status', 'ok', 'problems', 'pubkey_fingerprint', 'returncode', 'sig_info', 'sig_timestamp', 'signature_id', 'status', 'status_detail', 'stderr', 'timestamp', 'trust_level', 'trust_text', 'username', 'valid']:
	result_dict[prop] = getattr(result, prop, None)
return json.dumps(result_dict)
}

ClassMethod IsFileStream(stream As %Stream.Object) As %Boolean
{
	if stream.%Extends(##class(%Stream.FileBinary).%ClassName($$$YES)) || stream.%Extends(##class(%FileStreamAdaptor).%ClassName($$$YES)) {
		quit $$$YES
	}
	quit $$$NO
}

ClassMethod EncryptPy(gpg, fingerprint, plainFilename, encryptedFilename) [ Language = python ]
{
with open(plainFilename, 'rb') as f:
    result = gpg.encrypt_file(
        f,
        recipients=fingerprint,
        output=encryptedFilename,
    )
return result
}

Method Decrypt(request As DecryptionRequest, Output response As DecryptionResponse) As %Status
{
	#Dim sc As %Status = $$$OK
	
	Set isFileStream = ..IsFileStream(request.Stream)
    If request.ResponseFilename '= "" {
	    Set plainFilename = request.ResponseFilename
    } ElseIf isFileStream {
	    Set plainFilename = request.Stream.Filename _ ".txt"
    } Else {
	    Set plainFilename = ##class(%File).TempFilename("txt")
    }
    
    If isFileStream {
    	Set encryptedFilename = request.Stream.Filename
    } Else {
	    Set encryptedFilename = ##class(%File).TempFilename("asc")
	    Set encryptedStream = ##class(%Stream.FileCharacter).%New()
	    $$$TOE(sc, encryptedStream.LinkToFile(encryptedFilename))
	    $$$TOE(sc, encryptedStream.CopyFromAndSave(request.Stream))
	    Kill encryptedStream
    }
    Set result = ..DecryptPy(..%GPG, encryptedFilename, plainFilename)
   
    If isFileStream || (request.ResponseFilename '= "") {
	    Set response = ##class(FileDecryptionResponse).%New()
    } Else { 
		Set response = ##class(DecryptionResponse).%New()
    }
	//Set response.Stream = $system.OBJ.New(request.Stream.%ClassName($$$YES))
	
	If isFileStream || (request.ResponseFilename '= "") {
		$$$TOE(sc, response.Stream.LinkToFile(plainFilename))
	} Else {
		Do ##class(%File).Delete(encryptedFilename)
	    Set plainStream = ##class(%Stream.FileBinary).%New()
	    $$$TOE(sc, plainStream.LinkToFile(plainFilename))
	    $$$TOE(sc, response.Stream.CopyFromAndSave(plainStream))
	    Kill plainStream
	    Do ##class(%File).Delete(plainFilename)		
	}
	
    Set response.Result = ..ProcessResult(result)
    Do ..CheckResultObject(response.Result)	
    
    Quit sc
}

ClassMethod DecryptPy(gpg, encryptedFilename, plainFilename) [ Language = python ]
{
with open(encryptedFilename, 'rb') as f:
    result = gpg.decrypt_file(
        f,
        output=plainFilename,
    )
return result
}

Method Sign(request As SignRequest, Output response As SignResponse) As %Status
{
	#Dim sc As %Status = $$$OK

	Set isFileStream = ..IsFileStream(request.Stream)
    If request.ResponseFilename '= "" {
	    Set signFilename = request.ResponseFilename
    } ElseIf isFileStream {
	    Set signFilename = request.Stream.Filename _ ".asc"
    } Else {
	    Set signFilename = ##class(%File).TempFilename("asc")
    }
    
    If isFileStream {
    	Set dataFilename = request.Stream.Filename
    } Else {
	    Set dataFilename = ##class(%File).TempFilename("txt")
	    Set dataStream = ##class(%Stream.FileCharacter).%New()
	    $$$TOE(sc, dataStream.LinkToFile(dataFilename))
	    $$$TOE(sc, dataStream.CopyFromAndSave(request.Stream))
	    Kill dataStream
    }
    Set result = ..SignPy(..%GPG, dataFilename, signFilename)
   
    If isFileStream || (request.ResponseFilename '= "") {
	    Set response = ##class(FileSignResponse).%New()
    } Else { 
		Set response = ##class(SignResponse).%New()
    }
	
	If isFileStream || (request.ResponseFilename '= "") {
		$$$TOE(sc, response.Stream.LinkToFile(signFilename))
	} Else {
		Do ##class(%File).Delete(dataFilename)
	    Set signStream = ##class(%Stream.FileBinary).%New()
	    $$$TOE(sc, signStream.LinkToFile(signFilename))
	    $$$TOE(sc, response.Stream.CopyFromAndSave(signStream))
	    Kill signStream
	    Do ##class(%File).Delete(signFilename)		
	}
	
    Set response.Result = ..ProcessResult(result)
    Do ..CheckResultObject(response.Result)	
    
    Quit sc
}

ClassMethod SignPy(gpg, dataFilename, signFilename) [ Language = python ]
{
with open(dataFilename, 'rb') as f:
    result = gpg.sign_file(
        f,
        output=signFilename,
    )
return result
}

Method Verify(request As VerifyRequest, Output response As VerifyResponse) As %Status
{
	#Dim sc As %Status = $$$OK

	Set isFileStream = ..IsFileStream(request.Stream)
    
    If isFileStream {
    	Set signFilename = request.Stream.Filename
    } Else {
	    Set signFilename = ##class(%File).TempFilename("asc")
	    Set signStream = ##class(%Stream.FileBinary).%New()
	    $$$TOE(sc, signStream.LinkToFile(signFilename))
	    $$$TOE(sc, signStream.CopyFromAndSave(request.Stream))
	    Kill signStream
    }
    Set result = ..VerifyPy(..%GPG, signFilename)
   
    Set response = ##class(SignResponse).%New()
	
	If 'isFileStream {
		Do ##class(%File).Delete(signFilename)		
	}
	
    Set response.Result = ..ProcessResult(result)
    Do ..CheckResultObject(response.Result)	
    
    Quit sc
}

ClassMethod VerifyPy(gpg, signFilename) [ Language = python ]
{
with open(signFilename, 'rb') as f:
    result = gpg.verify_file(f)
return result
}

XData MessageMap
{
<MapItems>
<MapItem MessageType="Utils.GPG.EncryptionRequest">
<Method>Encrypt</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.FileEncryptionRequest">
<Method>Encrypt</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.DecryptionRequest">
<Method>Decrypt</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.FileDecryptionRequest">
<Method>Decrypt</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.SignRequest">
<Method>Sign</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.FileSignRequest">
<Method>Sign</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.VerifyRequest">
<Method>Verify</Method>
</MapItem>
<MapItem MessageType="Utils.GPG.FileVerifyRequest">
<Method>Verify</Method>
</MapItem>
</MapItems>
}

}

