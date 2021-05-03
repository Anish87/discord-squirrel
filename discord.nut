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
		local member   = message.Member, serverID = message.ServerID, authorID = message.Author.ID;
		local username = (member.Nick != null && member.Nick != "") ? member.Nick : message.Author.Username;
		
		if(authorID == null) return;
		if(authorID == "botID") return;
		if(message.Author.IsBot) return;
		if(authorID != "botID")
		{
			local highestRole = HighestRole(member.Roles);
			if(channels["echo"] == message.ChannelID)
			{
				if(message.Content.len() > 0 && message.Content.slice(0,1)=="!")
				{
					local cmd = GetTok(message.Content, " ", 1).slice(1);
					local text = GetTok(message.Content, " ", 2, split(message.Content, " ").len());
					local embed = SqDiscord.Embed.Embed();
                    /* I have added a few commands so that you can continue adding more of them. */
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
					EchoMessage("**"+username+"**[#ffffff]: "+message.Content+"");
					::Message(format("%s%s %s:[#FFFFFF]%s", highestRole.GetColor(), highestRole.GetName(), username, message.Content));
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

Discord <- MyDiscord();
Discord.Connect("botToken");

function onDiscordUpdate(connID, eventType, ...) 
{
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

/* Discord Roles */
DiscordRole <- {};
class DiscordRoles
{
    /* Defs */
    roleID = null;
    Name   = null;
    Color  = null;
    Level  = null;

    /* Init */
    constructor(RoleID, name, color, level)
    {
        this.roleID = RoleID;
        this.Name   = name;
        this.Color  = color;
        this.Level  = level;
        ::DiscordRole.rawset(RoleID, this);
    }

    /* Func */
    function GetID()
    {
        return this.roleID;
    }

    function GetLevel()
    {
        return this.Level;
    }

    function GetColor()
    {
        return "["+this.Color+"]";
    }

    function GetName()
    {
        return this.Name;
    }
}

// IDEAS FOR USAGE
/*

* You can use this class to use different level commands,
  for eg,
  'local level = HighestRole(roles).GetLevel();' will return an integer value, which you can use to authorize the commands accordingly.

* You can use it in the Echo from Discord to in-game, as given above in the script.

*/

// USAGE
/* DiscordRoles("roleID", "roleName", "roleColor(in hex format, for eg, #ffffff)", numericLevel); */

function HighestRole(roles)
{
    local highestRole = {
        "ID"    : "lowest role ID",
        "Level" : 1
    };
    foreach(role in roles)
    {
        if(DiscordRole.rawin(role) && DiscordRole[role].GetLevel().tointeger() > highestRole.Level.tointeger())
        {
            highestRole.ID    = DiscordRole[role].GetID();
            highestRole.Level = DiscordRole[role].GetLevel();
        }
    }
    return DiscordRole[highestRole.ID];
}
