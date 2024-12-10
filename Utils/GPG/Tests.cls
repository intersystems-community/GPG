/// Call BO manually.
/// Sample key required for signing and decryption is available in the repository.
Class Utils.GPG.Tests
{

Parameter TARGET = "Utils.GPG.Operation";

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

/// do ##class(Utils.GPG.Tests).Encrypt()
ClassMethod Decrypt(target = {..#TARGET}, encryptedFilename As %String, plainFilename As %String)
{
	if $d(encryptedFilename) {
		set request = ##class(FileDecryptionRequest).%New()
		set request.Stream = ##class(%Stream.FileBinary).%New()
		$$$TOE(sc, request.Stream.LinkToFile(encryptedFilename))
	} else {
		set request = ##class(DecryptionRequest).%New()
		set request.Stream = ##class(%Stream.GlobalBinary).%New()
		do request.Stream.WriteLine("-----BEGIN PGP MESSAGE-----")
		do request.Stream.WriteLine("")
		do request.Stream.WriteLine("hIwDOLeFwQPNDM4BA/oDGTtameZhjHg1MXlv+nWVLAcrObMJUw5nbWtzWSsZY4GP")
		do request.Stream.WriteLine("Va+H3nYpCrOe4Bh+RIRobP9rWCi6nK7zi2sxvgPnkTqtCVYQ4y5CiY9nhuXUdtz+")
		do request.Stream.WriteLine("K5qaojyU9MDiDumPa5mvWUKoaYaEQAXKTc+QIvnMHM5WB1CUOc0Uf9oWyIJnRdRR")
		do request.Stream.WriteLine("AQkCEN43CZFV1nrXQxcdVK/XzeWhDq3z6ePIw48U80NeKnIcWEeGLgZgmQFpn7FY")
		do request.Stream.WriteLine("9mCNDyPZUnZqOomgUDWpUuuG64RrRE+CzD1CJF+e2WaS")
		do request.Stream.WriteLine("=e4UN")
		do request.Stream.WriteLine("-----END PGP MESSAGE-----")
		$$$TOE(sc, request.Stream.%Save())
	}
	
	if $d(plainFilename) {
		set request.ResponseFilename = plainFilename
	}
		
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest(target, request, .response, .sessionid)
	
	zw sc, response, sessionid
}

/// do ##class(Utils.GPG.Tests).Sign()
ClassMethod Sign(target = {..#TARGET}, dataFilename As %String, signFilename As %String)
{
	if $d(dataFilename) {
		set request = ##class(FileSignRequest).%New()
		set request.Stream = ##class(%Stream.FileBinary).%New()
		$$$TOE(sc, request.Stream.LinkToFile(dataFilename))
	} else {
		set request = ##class(SignRequest).%New()
		set request.Stream = ##class(%Stream.GlobalBinary).%New()
		do request.Stream.Write("123456")
		$$$TOE(sc, request.Stream.%Save())
	}
	
	if $d(signFilename) {
		set request.ResponseFilename = signFilename
	}
		
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest(target, request, .response, .sessionid)
	
	zw sc, response, sessionid
}

/// do ##class(Utils.GPG.Tests).Verify()
ClassMethod Verify(target = {..#TARGET}, signFilename As %String)
{
	if $d(signFilename) {
		set request = ##class(FileVerifyRequest).%New()
		set request.Stream = ##class(%Stream.FileBinary).%New()
		$$$TOE(sc, request.Stream.LinkToFile(signFilename))
	} else {
		set request = ##class(VerifyRequest).%New()
		set request.Stream = ##class(%Stream.GlobalBinary).%New()
		do request.Stream.WriteLine("-----BEGIN PGP SIGNED MESSAGE-----")
		do request.Stream.WriteLine("Hash: SHA256")
		do request.Stream.WriteLine("")
		do request.Stream.WriteLine("123456")
		do request.Stream.WriteLine("-----BEGIN PGP SIGNATURE-----")
		do request.Stream.WriteLine("")
		do request.Stream.WriteLine("iLMEAQEIAB0WIQRvjN6i8q6k7bsqxlU4t4XBA80MzgUCZ1iq5QAKCRA4t4XBA80M")
		do request.Stream.WriteLine("zl/HBACZSnj5rAgs48gFl0M13zw/NgjMt3KSSATRR9ysZukiI0oisIpBipCWpcOO")
		do request.Stream.WriteLine("JicBL1AfmuTLbEQICyBGBlYpfqJ8Mh6a+gso9Oal1GjsVcOZphWPBdLw/w9QQCCO")
		do request.Stream.WriteLine("2fLqsLc3bW0RIm4AureokeRL9xzxHnE36cW0aNhGSa/pRAYsBw==")
		do request.Stream.WriteLine("=jemD")
		do request.Stream.WriteLine("-----END PGP SIGNATURE-----")
		$$$TOE(sc, request.Stream.%Save())
	}
	
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest(target, request, .response, .sessionid)
	
	zw sc, response, sessionid
}

}

