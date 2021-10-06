PluginInfo = {
    Name = "Lumens~LC200", -- The tilde here indicates folder structure in the Shematic Elements pane
    Version = "1.0",
    Id = "1b429f4d-6c33-4628-8984-0482703d2a53", -- show this is just a unique id. Show some commented out 'fun' unique ids
    Description = "A plugin for control a Lumens LC200 media streamer/player",
    ShowDebug = true,
    Author = "Fabio Feliciosi"
}

-- We can let users determine some of the plugin properties by exposing them here
-- While this function can be very useful, it is completely optional and not always needed.
-- If no Properties are set here, only the position and fill properties of your plugin will show in the Properties pane
function GetProperties()
    props = {
        {
            Name = "IP Address",
            Type = "string",
            Value = "192.168.1.1"
        },
        {
            Name = "Port",
            Type = "integer",
            Min = 1,
            Max = 65535,
            Value = 5080
        }
    }
    return props
end

-- The below function is where you will populate the controls for your plugin.
-- If you've written some of the Runtime code already, simply use the control names you populated in Text Controller/Control Script, and use their Properties to inform the values here
-- ControlType can be Button, Knob, Indicator or Text
-- ButtonType ( ControlType == Button ) can be Momentary, Toggle or Trigger
-- IndicatorType ( ControlType == Indicator ) can be Led, Meter, Text or Status
-- ControlUnit ( ControlType == Knob ) can be Hz, Float, Integer, Pan, Percent, Position or Seconds
function GetControls(props)
    ctls = {
        {
            Name = "RecordBtn",
            ControlType = "Button",
            ButtonType = "Toggle",
            Count = 1
        },
        {
            Name = "StreamBtn",
            ControlType = "Button",
            ButtonType = "Toggle",
            Count = 3
        },
        
    }
    return ctls
end

ButtonSize = {100,30}

function GetControlLayout(props)
    local layout = {}
    local graphics = {}

    local x = 15
    local y = 10

    layout["RecordBtn"] = {
        Style = "Button",
        ButtonStyle = "Toggle",
        Size = ButtonSize,
        Position = {x + ButtonSize[1],y},
        Legend = "Record Stop"
    }

    for z=1,3 do
        layout["StreamBtn "..z] = {
            Style = "Button",
            ButtonStyle = "Toggle",
            Size = ButtonSize,
            Position = {(z-1)*ButtonSize[1] + x + ButtonSize[1], y + ButtonSize[2]},
            Legend = "Stream "..z
        }
    end
    
    graphics = {
        {
            Type = "Label",
            Size = ButtonSize,
            Position = {x,y},
            Text = "Record"
        },
        {
            Type = "Label",
            Size = ButtonSize,
            Position = {x,y + ButtonSize[2]},
            Text = "Stream"
        },
        
    }

    return layout, graphics;

end

--Protocol variables
Header = "\x55\xF0"
DevAddress = "\x01"
Terminator = "\x0D"
SetAction = "\x73"
RecordStart = "\x52\x43"
RecordStop = "\x53\x50"
StreamHeader = "\x53\x43"
StreamStart = "\x01"
StreamStop = "\x02"
StreamSelection = {"\x31", "\x32", "\x33"}

if Controls then
    local sock = TcpSocket:New()
    sock.ReconnectTimeout = 5
    sock.ReadTimeout = 5
    sock.WriteTimeout = 5

    function VerifySend(Command)
        if sock.IsConnected == true then
            sock:Write(Command)
        else
            print("Cannot communicate with device, please check network and parameters.")
        end
    end

    function SendCommand(Command)
        if sock.IsConnected == true then
            sock:Write(Command)
        else
            sock:Connect(Properties["IP Address"].Value, Properties["Port"].Value )
            Timer.CallAfter( function() VerifySend(Command) end,1)
        end
    end

    

    local CommandString = ""

    Controls["RecordBtn"].EventHandler = function ()
        if Controls["RecordBtn"].Boolean == true then
            CommandString = Header..'\x04'..DevAddress..SetAction..RecordStart..Terminator
            SendCommand(CommandString)
            Controls["RecordBtn"].Legend = "Recording in progress."
            
        else
            CommandString = Header..'\x04'..DevAddress..SetAction..RecordStop..Terminator
            SendCommand(CommandString)
            Controls["RecordBtn"].Legend = "Start recording"
        end
    end

    for x=1,3 do
        Controls["StreamBtn"][x].EventHandler = function()
            if Controls["StreamBtn"][x].Boolean == true then
                CommandString = Header..'\x06'..DevAddress..SetAction..StreamHeader..StreamSelection[x]..StreamStart..Terminator
                SendCommand(CommandString)
            else
                CommandString = Header..'\x06'..DevAddress..SetAction..StreamHeader..StreamSelection[x]..StreamStop..Terminator
                SendCommand(CommandString)
            end
        end
    end

    sock.Data = function(sock)
        Incoming = sock:ReadLine(TcpSocket.EOL.Custom, "\x0d")
        print(Incoming)
    end
end