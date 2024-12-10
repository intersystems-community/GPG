/// Returned by a Verify call. Info about one signature.
Class Utils.GPG.SigInfo Extends (%Persistent, %XML.Adaptor, %JSON.Adaptor)
{

Property creationdate As %String(%JSONFIELDNAME = "creation_date");

Property timestamp As %String;

Property keyid As %String;

Property username As %VarString;

Property status As %String;

Property fingerprint As %String;

Property expiry As %String;

Property pubkeyfingerprint(%JSONFIELDNAME = "pubkey_fingerprint");

Property trustlevel As %Integer(%JSONFIELDNAME = "trust_level");

Property trusttext As %String(%JSONFIELDNAME = "trust_text");

Storage Default
{
<Data name="SigInfoDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>creationdate</Value>
</Value>
<Value name="3">
<Value>timestamp</Value>
</Value>
<Value name="4">
<Value>keyid</Value>
</Value>
<Value name="5">
<Value>username</Value>
</Value>
<Value name="6">
<Value>status</Value>
</Value>
<Value name="7">
<Value>fingerprint</Value>
</Value>
<Value name="8">
<Value>expiry</Value>
</Value>
<Value name="9">
<Value>pubkeyfingerprint</Value>
</Value>
<Value name="10">
<Value>trustlevel</Value>
</Value>
<Value name="11">
<Value>trusttext</Value>
</Value>
</Data>
<DataLocation>^Utils.GPG.SigInfoD</DataLocation>
<DefaultData>SigInfoDefaultData</DefaultData>
<IdLocation>^Utils.GPG.SigInfoD</IdLocation>
<IndexLocation>^Utils.GPG.SigInfoI</IndexLocation>
<StreamLocation>^Utils.GPG.SigInfoS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

