% Finding the Port of the Instrument
% Power on the instrument
% Connect the instrument to your computer
% Identify the port that the instrument/s are connected to
clear
% After powering on and connecting the instrument
% Scan ports on computer
port_list = serialportlist;

% Printing out ports
for i = 1:numel(port_list)
    fprintf ("Port #%d: %s\n", i, port_list(i))
end

% Connecting to the Instrument
% Choose the correct port
% Set dev1 and dev2 variables to the correct port
% Create object and connect to the device
% On Mac you might get something similar to this:
% "/dev/tty.usbserial-AR0KM0M8"

% On Windows you might get soothing similar to this:
% 

% Set your device variables equal to the ports
dev1 = 6; % Port number of device 1
dev2 = 2; % Port number of device 2 (optional)

% Creating an object for the serial communications
device1 = serialport(port_list(dev1), 38400)
% device2 = serialport(port_list(dev2), 38400)

% Sending the First Commands
% Write a command to the instrument
% Read the information from the instrument
% Get device information from instruments with basic commands
writeline(device1, "*idn?");
dev1idn = readline(device1);
fprintf("Device 1: %s", dev1idn)

% writeline(device2, "*idn?");
% dev2idn = readline(device2);
% fprintf("Device 1: %s", dev2idn)




% ----------------------------------------------------------------------------------------------------------------------------------------

% Changing Temperature and Enabling Output

% ----------------------------------------------------------------------------------------------------------------------------------------

% Changing Temperature and Enabling Output
% Change the Tset of the device
% Enable the output of the device
% Exploring concatenation
% Changing the Tset
Tset = 26;

% Creating the command and sending it to the device
Tcommand = sprintf("tec:t %d", Tset);
writeline(device1, Tcommand);

% Enable the output
writeline(device1, "tec:out 1");

% A note on concatenation
% Both commands can be combined by using the following syntax
% writeline(device1, "tec:t 25;out 0")

% Logging and Plotting Data
% Log and graph data over a user-defined amount of time
% User-defined log interval (1 Hz by default)
% Log all dynamic values

% Here are the user configured variables, adjust them to fit your purposes
% Configure polling frequency in hertz
polling_frequency = 10; %Hz

% Configure acquisition length in seconds
acquisition_length = 5; %sec

% Data lables for cell array
recorded_values = {"time",  "voltage",  "current",  "temp",  "resistance"};

figure(1)
vct_plot = axes();
hold(vct_plot, "on");



% Begin reading data
for readings = 1:(polling_frequency*acquisition_length)
    % Querey and recieve time, voltage, current, temperature, and resistance
    writeline(device1, "time?;tec:v?;ite?;t?;r?");
    raw_data = readline(device1);

    % Parse raw data
    parsed_data = strings(0);
    [token,~] = split(raw_data, ',');
    parsed_data = [parsed_data ; token];

    % fix time formatting
    time_variables = split(parsed_data(1), ':');
    t = sprintf("%s:%s:%s", time_variables(2:4));
    formatted_time = datetime(t, InputFormat = "HH:mm:ss.SS");
    
    % Create cell array with captured data
    recorded_values(end+1, :) = ...
    {
        formatted_time, 
        str2double(parsed_data(2)),
        str2double(parsed_data(3)),
        str2double(parsed_data(4)),
        str2double(parsed_data(5))
    };

    %Plot voltage, current, temperature versus time
    yyaxis left;
    plot( ...
        [recorded_values{2:end,1}],[recorded_values{2:end,2}], ... % Voltage
        [recorded_values{2:end,1}],[recorded_values{2:end,3}], ... % Current 
        "Parent", vct_plot);
    yyaxis right;
    plot( ...
        [recorded_values{2:end,1}],[recorded_values{2:end,4}], ... % Temperature
        "Parent", vct_plot);
    drawnow;
    pause(1/polling_frequency);

end

% Plot formatting
grid(vct_plot,"on");
title(vct_plot, "voltage, current, temperature versus time");
xlabel(vct_plot, "Time");
xtickangle(vct_plot, 45);
xtickformat(vct_plot,"auto")
legend(vct_plot, "Voltage (V)", "Current(A)", "Temperature(Celcius)");



% ----------------------------------------------------------------------------------------------------------------------------------------

% Changing of set point and logging of data until stable

% ----------------------------------------------------------------------------------------------------------------------------------------

% Changing of set point and logging of data until stable
% User selected tol time and tol temp
% User-defined log interval (1 Hz by default)
% Change set point and turn output on
% Log all dynamic values
% Log data until stable.
% Configure tol time
tol_time = 2; %sec (0.1 - 50)

% Configure tol temp
tol_temp = 1; %C (0.01 - 10)

% Configure polling frequency in hertz
polling_frequency = 10; %Hz

% Changing the Tset
Tset = 30;

% Data lables for cell array
tol_recorded_values = {"time",  "voltage",  "current",  "temp",  "resistance", "tolerence"};

figure(2)
tol_plot = axes();
hold(tol_plot, "on");

% Creating tolerance command and sending it to the device
tol_command = sprintf("tec:tol %d,%d", tol_temp, tol_time);
writeline(device1, tol_command)

% Creating temp command and sending it to the device
temp_command = sprintf("tec:t %d;out 1", Tset);
writeline(device1, temp_command)

out_tol = 1;

% Begin reading data
while out_tol
    pause(1/polling_frequency)
    % Querey and recieve time, voltage, current, temperature, and resistance
    writeline(device1, "time?;tec:v?;ite?;t?;r?;cond?");
    raw_data = readline(device1);

    % Parse raw data
    parsed_data = strings(0);
    [token,~] = split(raw_data, ',');
    parsed_data = [parsed_data ; token];
    
    out_tol = bitget(str2double(parsed_data(6)), 10);

    % fix time formatting
    time_variables = split(parsed_data(1), ':');
    t = sprintf("%s:%s:%s", time_variables(2:4));
    formatted_time = datetime(t, InputFormat = "HH:mm:ss.SS");
    
    % Create cell array with captured data
    tol_recorded_values(end+1, :) = ...
    {
        formatted_time, 
        str2double(parsed_data(2)),
        str2double(parsed_data(3)),
        str2double(parsed_data(4)),
        str2double(parsed_data(5)),
        out_tol
    };

    %Plot voltage, current, temperature versus time
    yyaxis left;
    plot( ...
        [tol_recorded_values{2:end,1}],[tol_recorded_values{2:end,2}], ... % Voltage
        [tol_recorded_values{2:end,1}],[tol_recorded_values{2:end,3}], ... % Current 
        "Parent", tol_plot);
    yyaxis right;
    plot( ...
        [tol_recorded_values{2:end,1}],[tol_recorded_values{2:end,4}], ... % Temperature
        "Parent", tol_plot);
    drawnow;
    

end

% Plot formatting
grid(tol_plot,"on");
title(tol_plot, "voltage, current, temperature versus time");
xlabel(tol_plot, "Time");
xtickangle(tol_plot, 45);
xtickformat(tol_plot,"auto")
legend(tol_plot, "Voltage (V)", "Current(A)", "Temperature(Celcius)");


% ----------------------------------------------------------------------------------------------------------------------------------------

% Ramping temperature and logging data until stable

% ----------------------------------------------------------------------------------------------------------------------------------------



% Ramping temperature and logging data until stable
% User selected tol time and tol temp
% User-defined log interval (1 Hz by default)
% Change set point and turn output on
% Log all dynamic values
% Log data until stable.

% Configure Min and Max temp
min_temp = 20; %C
max_temp = 25; %C

% Configure step size
step_size = 1; %C

% Configure tol time
tol_time = 4; %sec (0.1 - 50)

% Configure tol temp
tol_temp = 0.1; %C (0.01 - 10)

% Configure polling frequency in hertz
polling_frequency = 1; %Hz

% Begin ramping
% Changing the Tset
Tset = min_temp;

% Data lables for cell array
ramp_recorded_values = {"time",  "voltage",  "current",  "temp",  "resistance", "tolerence"};

figure(3)
ramp_plot = axes();
hold(ramp_plot, "on");

% Creating tolerance command and sending it to the device
tol_command = sprintf("tec:tol %d,%d", tol_temp, tol_time);
writeline(device1, tol_command)

% Creating temp command and sending it to the device
temp_command = sprintf("tec:t %d;out 1", Tset);
writeline(device1, temp_command)

out_tol = 1;
acquiring = 1;

% Begin reading data
while acquiring
    % Query and receive time, voltage, current, temperature, and resistance
    fprintf("Acquired\n");
    writeline(device1, "time?;tec:v?;ite?;t?;r?;cond?");
    pause(1/polling_frequency)
    raw_data = readline(device1);

    % Parse raw data
    parsed_data = strings(0);
    [token,~] = split(raw_data, ',');
    parsed_data = [parsed_data ; token];
    
    out_tol = bitget(str2double(parsed_data(6)), 10);

    % fix time formatting
    time_variables = split(parsed_data(1), ':');
    t = sprintf("%s:%s:%s", time_variables(2:4));
    formatted_time = datetime(t, InputFormat = "HH:mm:ss.SS");
    
    % Create cell array with captured data
    ramp_recorded_values(end+1, :) = ...
    {
        formatted_time, 
        str2double(parsed_data(2)),
        str2double(parsed_data(3)),
        str2double(parsed_data(4)),
        str2double(parsed_data(5)),
        out_tol
    };
    %Plot voltage, current, temperature versus time
    yyaxis left;
    plot( ...
        [ramp_recorded_values{2:end,1}],[ramp_recorded_values{2:end,2}], ... % Voltage
        [ramp_recorded_values{2:end,1}],[ramp_recorded_values{2:end,3}], ... % Current 
        "Parent", ramp_plot);
    yyaxis right;
    plot( ...
        [ramp_recorded_values{2:end,1}],[ramp_recorded_values{2:end,4}], ... % Temperature
        "Parent", ramp_plot);
    drawnow;
    
    if ~out_tol
        if Tset < max_temp
            Tset = Tset + step_size;
            temp_command = sprintf("tec:t %d;out 1", Tset);
            writeline(device1, temp_command);
            out_tol = 1;
            pause(.04); % Allow command to be sent
        else
            acquiring = 0;
        end
    end
end

% Plot formatting
grid(ramp_plot,"on");
title(ramp_plot, "voltage, current, temperature versus time");
xlabel(ramp_plot, "Time");
xtickangle(ramp_plot, 45);
xtickformat(ramp_plot,"auto")
legend(ramp_plot, "Voltage (V)", "Current(A)", "Temperature(Celcius)");
