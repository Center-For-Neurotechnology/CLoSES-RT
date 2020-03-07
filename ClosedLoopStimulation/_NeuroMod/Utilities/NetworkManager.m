classdef NetworkManager
    % The Network Manager class interfaces with Windows Network and Sharing
    % Center to populate a list of network interfaces and toggle the IP
    % addresses from static to dynamic. Tested in Windows 7.
    
    % Usage:
    % NM = NetworkManager;
    
    % NM = NM.SetStatic('NSPNet','192.168.137.1')
    % (or)
    % NM = NM.SetStatic('192.168.137.1','192.168.137.2')
    % (or)
    % NM = NM.SetStatic(2,'192.168.137.2')
    
    % NM = NM.SetDynamic('NSPNet')
    % (or)
    % NM = NM.SetDynamic('192.168.137.1')
    % (or)
    % NM = NM.SetDynamic(2)
    
    % NM = NM.Rename('NSPnet','NSP2')
    % (or)
    % NM = NM.Rename('192.168.137.1','NSP2')
    % (or)
    % NM = NM.Rename(2,'NSP2')
    
    % NM = NM.Refresh

    % Anish A. Sarma, BrainGate, 2015.11.12
    properties
        interfaces % struct delineating names and IP addresses
    end
    methods
        % Construct the Network Manager
        function obj = NetworkManager
            % Check that we're on windows
            if isunix || ismac
                error('This OS is not supported!')
            end
            % Search for the IPv4 interfaces on this machine
            % Call "ipconfig" to get a list of all net information
            [failFlag,ipStr] = system('ipconfig');
            if failFlag
                error('IP Config failed for some reason.')
            end
            % Find all ethernet adapters
            adapterLeftInds = regexpi(ipStr,'Ethernet adapter ','end');
            % Search through the list from bottom to top
            for ethInd = length(adapterLeftInds):-1:1;
                thisEthInd = adapterLeftInds(ethInd);
                % Look at the section of the string near this adapter
                subStr = ipStr(thisEthInd:end);
                % Find the first colon in the subsection
                nameRightInds = regexpi(subStr,'(.):');
                % The adapter name is from the start of the subsection to
                % the colon.
                adapterName = subStr(2:nameRightInds);
                % Find an IPv4...: in the subsection
                addressLeftInd = regexpi(subStr,'IPv4(.{1,30}): ','end');
                % Extract the IP address after that colon.
                addressFragment = subStr((addressLeftInd+1):(addressLeftInd+20));
                addressRightInd = regexpi(addressFragment,'\n','end');
                adapterAddress = addressFragment(1:(addressRightInd-1));
                % Display the adapters we found
                if ~isempty(adapterAddress)
                    fprintf('%s: %s\n',adapterName,adapterAddress);
                else
                    fprintf('%s: Not connected. \n',adapterName);
                end
                % Shorten the main string, since we've searched this
                % section already.
                ipStr = ipStr(1:thisEthInd);
                obj.interfaces(ethInd).adapterName = adapterName;
                obj.interfaces(ethInd).ipAddress = adapterAddress;
                obj.interfaces(ethInd).isValid = ~isempty(adapterAddress);
            end
        end
        function obj = SetStatic(obj,adapterID,targetAddress)
            % Set a given adapter to a fixed IP address
            
            % First, disambiguate the adapter ID input (see Match subfcn)
            adapterID = obj.MatchID(adapterID);
            % Is this adapter connected (and therefore a candidate for this
            % kind of assignment)?
            if ~obj.interfaces(adapterID).isValid
                error('This interface is not connected.')
            end
            
            % Assemble the shell command that will make this possible
            netshStr = sprintf('netsh int ip set address "%s" static %s 255.255.255.0 0.0.0.0',...
                obj.interfaces(adapterID).adapterName,...
                targetAddress...
                );
            % Execute the system command
            [failFlag,outStr] = system(netshStr);
            % Did you succeed?
            if failFlag
                error('The call to NetShell failed!')
            end
            fprintf('Done. %s is now on %s.\n',...
                obj.interfaces(adapterID).adapterName,targetAddress);
            % If you succeeded, update the manager object.
            obj.interfaces(adapterID).ipAddress = targetAddress;
        end
        
        function obj = SetDynamic(obj,adapterID)
            % Set a given adapter to a dynamic IP address (i.e. if you need
            % to connect to the outside world).
            
            % First, disambiguate the adapter ID input (see Match subfcn)
            adapterID = obj.MatchID(adapterID);
            % Is this adapter connected (and therefore a candidate for this
            % kind of assignment)?
            if ~obj.interfaces(adapterID).isValid
                error('This interface is not connected.')
            end
            
            % Assemble the shell command that will make this possible
            netshStr = sprintf('netsh int ip set address "%s" dhcp',...
                obj.interfaces(adapterID).adapterName);
            % Execute the system command
            [failFlag,outStr]  = system(netshStr);
            % Did you succeed?
            if failFlag
                if any(strfind(outStr,'DHCP is already enabled'))
                    % That's not really a failure. Ignore.
                else
                    fprintf(outStr);
                    error('The call to NetShell failed! Run as admin?')
                end
            end
            % If you succeeded, update the manager object. We don't know
            % what the resulting address was, so we need to find it in the
            % NetShell.
            % Assemble the NetShell command...
            netshStr = sprintf('netsh interface ip show config name="%s"',...
                obj.interfaces(adapterID).adapterName);
            % Execute...needs to happen a few times, for some reason.
            addressLineInd = [];
            fprintf('..')
            while isempty(addressLineInd)
                [failFlag,outStr] = system(netshStr);
                
                % Did you succeed?
                if failFlag
                    error('NetShell failed to find the dynamic address')
                end
                % Search through the output to find the address string
                addressLineInd = regexpi(outStr,'IP Address: ','end');
                fprintf('.')
            end
            subStr = outStr(addressLineInd:end);
            addressLeftInd = regexpi(subStr,'\S');
            addressLeftInd = addressLeftInd(1);
            addressRightInd = regexpi(subStr,'\n');
            resultAddress = subStr(addressLeftInd:(addressRightInd-1));
            obj.interfaces(adapterID).ipAddress = resultAddress;
            fprintf('Done. %s is now on %s.\n',...
                obj.interfaces(adapterID).adapterName,resultAddress);
            
        end
        
        function obj = Rename(obj,adapterID,newName)
            % Set a given adapter to a dynamic IP address (i.e. if you need
            % to connect to the outside world).
            
            % First, disambiguate the adapter ID input (see Match subfcn)
            adapterID = obj.MatchID(adapterID);
            originalName = obj.interfaces(adapterID).adapterName;
            
            % Assemble the shell command that will make this possible
            netshStr = sprintf(['netsh interface set interface '...
                'name = "%s" newname ="%s"'],...
                obj.interfaces(adapterID).adapterName,newName);
            % Execute the system command
            [failFlag,outStr]  = system(netshStr);
            % Did you succeed?
            if failFlag
                    fprintf(outStr);
                    error('The call to NetShell failed! Run as admin?')
            end
            % If you succeeded, update the manager object. We don't know
            % what the resulting address was, so we need to find it in the
            % NetShell.
            % Assemble the NetShell command...
            netshStr = sprintf('netsh interface ip show config name="%s"',...
                newName);
            % Execute...needs to happen a few times, for some reason.
            fprintf('..')
            while true
                [failFlag,outStr] = system(netshStr);
                
                % Did you succeed?
                if ~failFlag
                    break
                end                
                fprintf('.')
            end
            obj.interfaces(adapterID).adapterName = newName;
            fprintf('Done. %s is now %s.\n',...
                originalName,newName);
            
        end
        
        function adapterID = MatchID(obj,ambiguousID)
            % We'd like to disambiguate interfaces identified by their
            % string names, their IP addresses, and their locations in the
            % existing NetworkManager struct.
            if isnumeric(ambiguousID)
                % If it's a number, it should be a valid index into the
                % interface structure.
                try
                    % Try to index into interfaces.
                    obj.interfaces(ambiguousID);
                    % Great! That's disambiguated now.
                    adapterID = ambiguousID;
                    return
                catch
                    error('You specified an invalid interface!')
                end
            elseif ischar(ambiguousID)
                % If it's a string, it should refer to something in the
                % interfaces structure - either an IP or a name.
                for ethInd = 1:length(obj.interfaces)
                    % Check for each individual interface
                    if strcmpi(obj.interfaces(ethInd).adapterName,ambiguousID) ...
                            || strcmpi(obj.interfaces(ethInd).adapterName,ambiguousID)
                        % Found a match? Great, disambiguated.
                        adapterID = ethInd;
                        return
                    end
                end
                % If we haven't found something and returned yet, this
                % isn't a match, sorry.
                error('That interface doesn''t exist!')
            else
                % If it's not a number or a string, that's wrong.
                error('You specified an invalid interface data type!')
            end
            
        end
        function obj = Refresh(obj)
            % Go back into control panel and rebuild the object.
            obj = NetworkManager;
        end
    end
end