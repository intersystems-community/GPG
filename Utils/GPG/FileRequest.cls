Class Utils.GPG.FileRequest Extends (%Persistent, Ens.Request)
{

/// Stream to perform GPG operation on.
Property Stream As %Stream.FileBinary;

/// If set, the response would be placed in a file at the specified location.
/// If not set, response would add a .asc to the inbound filename. 
Property ResponseFilename As %VarString;

Storage Default
{
<Data name="FileRequestDefaultData">
<Subscript>"FileRequest"</Subscript>
<Value name="1">
<Value>Stream</Value>
</Value>
<Value name="2">
<Value>ResponseFilename</Value>
</Value>
<Value name="3">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Utils.GPG.FileRequestD</DataLocation>
<DefaultData>FileRequestDefaultData</DefaultData>
<IdLocation>^Utils.GPG.FileRequestD</IdLocation>
<IndexLocation>^Utils.GPG.FileRequestI</IndexLocation>
<StreamLocation>^Utils.GPG.FileRequestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

