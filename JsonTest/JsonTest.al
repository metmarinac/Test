codeunit 50103 RefreshALIssueCode
{
    procedure Refresh();
    var
        HttpClient : HttpClient;
        ResponseMessage : HttpResponseMessage;

        ALIssueTest : Record ALIssueTest;
        JsonToken : JsonToken;
        JsonValue : JsonValue;
        JsonObject : JsonObject;
        JsonArray : JsonArray;
        tJsonText : text;
        i : Integer;
    begin
        ALIssueTest.DeleteAll;

        // Simple web service call
        HttpClient.DefaultRequestHeaders.Add('User-Agent','Dynamics 365');
        if not HttpClient.Get('https://api.github.com/repos/Microsoft/AL/issues',
                              ResponseMessage)
        then
            Error('The call to the web service failed.');
        
        //Test GIT fdfdfd erere
        if not ResponseMessage.IsSuccessStatusCode then
            error('The web service returned an error message:\\' +
                  'Status code: %1\' +
                  'Description: %2',
                  ResponseMessage.HttpStatusCode,
                  ResponseMessage.ReasonPhrase);
        
        ResponseMessage.Content.ReadAs(tJsonText);
        
        // Process JSON response
        if not JsonArray.ReadFrom(tJsonText) then
            Error('Invalid response, expected an JSON array as root object');
        
        for i := 0 to JsonArray.Count - 1 do begin
            JsonArray.Get(i,JsonToken);
            JsonObject := JsonToken.AsObject;
            ALIssueTest.init;
            if not JsonObject.Get('id',JsonToken) then
                error('Could not find a token with key %1');
            
            ALIssueTest.id := JsonToken.AsValue.AsInteger;
            ALIssueTest.number := GetJsonToken(JsonObject,'number').AsValue.AsInteger;
            ALIssueTest.title := GetJsonToken(JsonObject,'title').AsValue.AsText;
            ALIssueTest.user := SelectJsonToken(JsonObject,'$.user.login').AsValue.AsText;
            ALIssueTest.state := GetJsonToken(JsonObject,'state').AsValue.AsText;
            ALIssueTest.html_url := GetJsonToken(JsonObject,'html_url').AsValue.AsText;
            ALIssueTest.Insert;
        end;
    end;
    procedure GetJsonToken(JsonObject:JsonObject;TokenKey:text)JsonToken:JsonToken;
    begin
        if not JsonObject.Get(TokenKey,JsonToken) then
            Error('Could not find a token with key %1',TokenKey);
    end;
    procedure SelectJsonToken(JsonObject:JsonObject;Path:text)JsonToken:JsonToken;
    begin
        if not JsonObject.SelectToken(Path,JsonToken) then
            Error('Could not find a token with path %1',Path);
    end;
}

table 50102 ALIssueTest
{

    fields
    {
        field(1;id;Integer)
        {
            CaptionML=ENU='ID';
        }
        field(2;number;Integer)
        {
            CaptionML=ENU='Number';
        }
        field(3;title;text[250])
        {
            CaptionML=ENU='Title';
        }
        field(5;created_at;DateTime)
        {
            CaptionML=ENU='Created at';
        }
        field(6;user;text[50])
        {
            CaptionML=ENU='User';
        }
        field(7;state;text[30])
        {
            CaptionML=ENU='State';
        }
        field(8;html_url;text[250])
        {
            CaptionML=ENU='URL';
        }
    }

    keys
    {
        key(PK;id)
        {
            Clustered = true;
        }
    }

    procedure RefreshIssues();
    var
        RefreshALIssues :Codeunit RefreshALIssueCode;
    begin
        RefreshALIssues.Refresh();
    end;

}

page 50102 ALIssueList
{
    PageType = List;
    SourceTable = ALIssueTest;
    CaptionML=ENU='AL Issues';
    Editable = false;
    SourceTableView=order(descending);

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Number;number) {}
                field(Title;title) {}
                field(CreatedAt;created_at) {}
                field(User;user) {}
                field(State;state) {}
                field(URL;html_url) 
                {
                    ExtendedDatatype=URL;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshALIssueList)
            {
                CaptionML=ENU='Refresh Issues';
                Promoted=true;
                PromotedCategory=Process;
                Image=RefreshLines;
                trigger OnAction();
                begin
                    RefreshIssues();
                    CurrPage.Update;
                    if FindFirst then;
                end;
            }
        }
    }

    trigger OnOpenPage();
    begin
        //RefreshIssues();
        //if FindFirst then;
    end;
}