Class Utils.GPG.Request Extends (%Persistent, Ens.Request, %XML.Adaptor)
{

/// Stream to perform GPG operation on.
Property Stream As %Stream.GlobalBinary;

/// If set, the response would be placed in a file at the specified location.
/// If not set, response would return %Stream.GlobalBinary.
Property ResponseFilename As %VarString;

Storage Default
{
<Data name="RequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Stream</Value>
</Value>
<Value name="3">
<Value>ResponseFilename</Value>
</Value>
</Data>
<DataLocation>^Utils.GPG.RequestD</DataLocation>
<DefaultData>RequestDefaultData</DefaultData>
<IdLocation>^Utils.GPG.RequestD</IdLocation>
<IndexLocation>^Utils.GPG.RequestI</IndexLocation>
<StreamLocation>^Utils.GPG.RequestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

