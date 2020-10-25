sessions <- {};

class MyDiscord
{
	eventFuncs = null;
	session = null;
	connID	= null;
	channels = null;
	
	function constructor()
	{
		session = SqDiscord.CSession();
		connID = session.ConnID;
		channels = { 
			"echo" : "echoChannelID",
			/*You can add more channels here, don't forget to add a comma before channel alias when adding more channels, for example:
			"ch1" : "channelID",
			"ch2" : "channelID"
			*/
		};
		
		sessions.rawset(connID, this);
		
		eventFuncs = [
			onReady,
			onMessage,
			onError,
			onDisconnect,
			onQuit
		];
		
		session.InternalCacheEnabled = true;
	}
	
	function Connect(token)
	{
		session.Connect(token);
	}
	
	function sendMessage(channelID, message)
	{
		session.Message(channelID, message);
	}
	
	function sendEmbed(channelID, embed)
	{
		session.MessageEmbed(channelID, "", embed);
	}

	function onReady() 
	{
		print("Discord bot connection established successfully.");
		session.SetActivity(::GetServerName()); /*This sets the bot stats to 'Playing (Server's Name)'*/
	}
	
	function onMessage(message) {
		local member = message.Member;
		local serverID = message.ServerID;
		local authorID = message.Author.ID;

		if(authorID == null) return;
		if(authorID == "botUserID") return;
		if(message.Author.IsBot) return;
		if(authorID != "botUserID")
		{
			local role;
			local lvl;
			if(message.Member.Roles.find("roleID") != null)
			{
				role = "Player";
				lvl = 1;
			}
			/*You can repeat this condition with and 'else if' in case you want more roles. 
			For Example,
			else if(message.Member.Roles.find("roleID") != null)
			{
				role = "Player/Developer/Staff/VIP"(any string can be used);
				lvl = 0/1/2/3;(any integer can be used);
			}
			I added this for convenience for those who want certain commands to be restricted to specific group of people. Say, staff etc. */
			if(channels["echo"] == message.ChannelID)
			{
				if(message.Content.len() > 0 && message.Content.slice(0,1)=="!")
				{
					local cmd = GetTok(message.Content, " ", 1).slice(1);
					local text = GetTok(message.Content, " ", 2, split(message.Content, " ").len());
					local embed = SqDiscord.Embed.Embed();
          /*I have added a few commands so that you can continue adding more of them.*/
					switch(cmd)
					{
						case "cmds":
						{
							embed.SetTitle("Available Commands");
							embed.SetDescription("cmds, ping, fps, players");
							embed.SetColor(0xfff000);
							sendEmbed(channels["echo"], embed);
							break;
						}
						case "players":
						{
							local str = "";
							embed.SetTitle("any string");
							for(local i = 0, plr; i < ::GetMaxPlayers(); ++i)
							{
								plr = FindPlayer(i);
								if(plr)
								{
									str += format("\n(%i) %s", plr.ID, plr.Name);
								}
							}
							if(str == "") embed.SetDescription(":sob: There is no one in-game.");
							else embed.SetDescription(format("Players in-game: [%i] %s", ::GetPlayers(), str));
							sendEmbed(channels["echo"], embed);
							break;
						}
						case "ping":
						{
							if(!text) EchoMessage("Please specify the player's name whose ping you want to see.");
							else
							{
								local plr = ::GetPlayer(text);
								EchoMessage(plr.Name+"'s ping is: **"+plr.Ping+"**");
							}
							break;
						}
						case "fps":
						{
							if(!text) EchoMessage("Please specify the player's name whose FPS you want to see.");
							else
							{
								local plr = ::GetPlayer(text);
								EchoMessage(plr.Name+"'s FPS is: **"+plr.FPS+"**");
							}
							break;
						}
						default:
						{
							EchoMessage("Unknown command.");
							break;
						}
					}
				}
				else
				{
					EchoMessage(role+" "+message.Author.Username+": "+message.Content+"");
					if(lvl == 1) ::Message("[Discord] [#FFF000]Player "+message.Author.Username+": [#FFFFFF]"+message.Content+"");
					/* Use an else if condition here as well if you added more 'lvl' values above in script.*/
					else ::Message("[Discord] [#FFF000]Player "+message.Author.Username+": [#FFFFFF]"+message.Content+"");
				}
			}
		}
	}
	
	function onError(code, message) {
		print(format("%d - %s", code, message));
	}
	
	function onDisconnect() {
		print("Discord session has disconnected.");
	}
	
	function onQuit() {
		print("Discord session has quit.");
	}
}

myDiscord <- MyDiscord();
myDiscord.Connect("your bot token");

function onDiscordUpdate(connID, eventType, ...) {
	if(sessions.rawin(connID)) {
		local session = sessions.rawget(connID);
		vargv.insert(0, session); //env
		session.eventFuncs[eventType].acall(vargv);
	}
}

function EchoMessage(message) 
{
	if (sessions.rawin(0))
	{
		sessions.rawget(0).sendMessage(sessions.rawget(0).channels["echo"], message);
	}
}
