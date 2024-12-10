Class Utils.GPG.FileResponse Extends (%Persistent, Ens.Response)
{

/// Stream to perform GPG operation on.
Property Stream As %Stream.FileBinary;

/// Result object operation details.
Property Result As Result(XMLREFERENCE = "COMPLETE");

Storage Default
{
<Data name="FileResponseDefaultData">
<Subscript>"FileResponse"</Subscript>
<Value name="1">
<Value>Stream</Value>
</Value>
<Value name="2">
<Value>Result</Value>
</Value>
<Value name="3">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Utils.GPG.FileResponseD</DataLocation>
<DefaultData>FileResponseDefaultData</DefaultData>
<IdLocation>^Utils.GPG.FileResponseD</IdLocation>
<IndexLocation>^Utils.GPG.FileResponseI</IndexLocation>
<StreamLocation>^Utils.GPG.FileResponseS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

