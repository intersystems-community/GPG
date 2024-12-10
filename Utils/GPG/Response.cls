Class Utils.GPG.Response Extends (%Persistent, Ens.Response, %XML.Adaptor)
{

/// Stream to perform GPG operation on.
Property Stream As %Stream.GlobalBinary;

/// Result object operation details.
Property Result As Result(XMLREFERENCE = "COMPLETE");

Storage Default
{
<Data name="ResponseDefaultData">
<Subscript>"Response"</Subscript>
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
<DataLocation>^Utils.GPG.ResponseD</DataLocation>
<DefaultData>ResponseDefaultData</DefaultData>
<IdLocation>^Utils.GPG.ResponseD</IdLocation>
<IndexLocation>^Utils.GPG.ResponseI</IndexLocation>
<StreamLocation>^Utils.GPG.ResponseS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

