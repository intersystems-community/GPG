Class Utils.GPG.Result Extends (%Persistent, %XML.Adaptor, %JSON.Adaptor)
{

Property creationdate As %String(%JSONFIELDNAME = "creation_date");

Property data As %String;

Property expiretimestamp As %String(%JSONFIELDNAME = "expire_timestamp");

Property fingerprint As %String;

Property keyid As %String(%JSONFIELDNAME = "key_id");

Property keystatus As %String(%JSONFIELDNAME = "key_status");

Property ok As %Boolean;

Property problems As list Of %String;

Property pubkeyfingerprint As %String(%JSONFIELDNAME = "pubkey_fingerprint");

Property returncode As %Integer;

Property siginfo As array Of SigInfo(%JSONFIELDNAME = "sig_info");

Property sigtimestamp As %String(%JSONFIELDNAME = "sig_timestamp");

Property signatureid As %String(%JSONFIELDNAME = "signature_id");

Property status As %String;

Property statusdetail As %String(%JSONFIELDNAME = "status_detail");

Property stderr As %VarString;

Property timestamp As %String;

Property trustlevel As %Integer(%JSONFIELDNAME = "trust_level");

Property trusttext As %String(%JSONFIELDNAME = "trust_text");

Property username As %VarString;

Property valid As %Boolean;

Storage Default
{
<Data name="ResultDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>creationdate</Value>
</Value>
<Value name="3">
<Value>data</Value>
</Value>
<Value name="4">
<Value>expiretimestamp</Value>
</Value>
<Value name="5">
<Value>fingerprint</Value>
</Value>
<Value name="6">
<Value>handlestatus</Value>
</Value>
<Value name="7">
<Value>keyid</Value>
</Value>
<Value name="8">
<Value>keystatus</Value>
</Value>
<Value name="9">
<Value>ok</Value>
</Value>
<Value name="10">
<Value>problems</Value>
</Value>
<Value name="11">
<Value>pubkeyfingerprint</Value>
</Value>
<Value name="12">
<Value>returncode</Value>
</Value>
<Value name="13">
<Value>siginfo</Value>
</Value>
<Value name="14">
<Value>sigtimestamp</Value>
</Value>
<Value name="15">
<Value>signatureid</Value>
</Value>
<Value name="16">
<Value>status</Value>
</Value>
<Value name="17">
<Value>statusdetail</Value>
</Value>
<Value name="18">
<Value>stderr</Value>
</Value>
<Value name="19">
<Value>timestamp</Value>
</Value>
<Value name="20">
<Value>trustlevel</Value>
</Value>
<Value name="21">
<Value>trusttext</Value>
</Value>
<Value name="22">
<Value>username</Value>
</Value>
<Value name="23">
<Value>valid</Value>
</Value>
</Data>
<DataLocation>^Utils.GPG.ResultD</DataLocation>
<DefaultData>ResultDefaultData</DefaultData>
<IdLocation>^Utils.GPG.ResultD</IdLocation>
<IndexLocation>^Utils.GPG.ResultI</IndexLocation>
<StreamLocation>^Utils.GPG.ResultS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

