%% ------------------------------------------------------------------
%% setkey_handler manages the request to set the Auth key
%% ------------------------------------------------------------------


-module(setkey_handler).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, []}.

handle(Req, _State) ->
	{Method, Req2} = cowboy_req:method(Req),
	HasBody = cowboy_req:has_body(Req2),
	{ok, ParsedQueryString, Req3} = cowboy_req:body_qs(Req2),
	{_, Player} = lists:keyfind(<<"user_id">>, 1, ParsedQueryString),
	Pid1 = tag_riak:connect(Player),
	{ok, Req4} = store_info(Method, HasBody, Req3, Pid1, ParsedQueryString),
	{ok, Req4, Pid1}.

store_info(<<"POST">>, true, Req, Pid, ParsedQueryString) ->
	Result = tag_riak:setkey(Pid, ParsedQueryString),
	if Result =:= bad_request
		-> cowboy_req:reply(400, [], <<"Body format incorrect.">>, Req);
		true -> cowboy_req:reply(200, [
			{<<"content-type">>, <<"text/plain; charset=utf-8">>}
		], Result, Req)
	end;


store_info(<<"POST">>, false, Req, _, _) ->
	cowboy_req:reply(400, [], <<"Missing body.">>, Req);
store_info(_, _, Req, _,_) ->
	%% Method not allowed.
	cowboy_req:reply(405, Req).


terminate(_Reason, _Req, State) ->
	tag_riak:close_server(State),
	ok.
