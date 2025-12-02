@echo off
setlocal enabledelayedexpansion

set /p BASIC_CONFIG=Do you want to configure basic settings (hostname, passwords)? (y/n): 
if /i "%BASIC_CONFIG%"=="y" goto configure_basic
if /i "%BASIC_CONFIG%"=="n" goto check_ssh
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_basic
set /p HOSTNAME=Device hostname: 
if "%HOSTNAME%"=="" goto error_hostname

set /p EXECpass=Privileged EXEC mode password: 
if "%EXECpass%"=="" goto error_exec

set /p CONSOLEpass=Line Console password: 
if "%CONSOLEpass%"=="" goto error_console

:check_ssh
set /p SSH_CONFIG=Do you want to configure SSH? (y/n): 
if /i "%SSH_CONFIG%"=="y" goto configure_ssh
if /i "%SSH_CONFIG%"=="n" goto check_vlan
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_ssh
set /p DOMAIN=Domain name: 
if "%DOMAIN%"=="" goto error_domain

set /p USERNAME=Username for new user: 
if "%USERNAME%"=="" goto error_username

set /p USERPASS=Password for new user: 
if "%USERPASS%"=="" goto error_userpass

set /p MODULUS=RSA key modulus (512-2048): 
if "%MODULUS%"=="" goto error_modulus

rem Generate commands with SSH
(
    echo enable
    echo conf t
    if /i "%BASIC_CONFIG%"=="y" (
        echo enable secret %EXECpass%
        echo hostname %HOSTNAME%
        echo line console 0
        echo password %CONSOLEpass%
        echo exit
    )
    echo ip domain-name %DOMAIN%
    echo username %USERNAME% secret %USERPASS%
    echo crypto key generate rsa general-keys modulus %MODULUS%
    echo line vty 0 15
    echo transport input ssh
    echo login local
    echo exit
) > "%~dp0commands.txt"
goto check_vlan

:check_vlan
set /p VLAN_CONFIG=Do you want to configure VLANs on switch? (y/n): 
if /i "%VLAN_CONFIG%"=="y" goto configure_vlan
if /i "%VLAN_CONFIG%"=="n" goto check_interface
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_vlan
set /p VLAN_ID=VLAN number: 
if "%VLAN_ID%"=="" goto error_vlan_id

set /p VLAN_NAME=VLAN name: 
if "%VLAN_NAME%"=="" goto error_vlan_name

rem Add VLAN commands to file
(
    echo vlan %VLAN_ID%
    echo name %VLAN_NAME%
    echo exit
) >> "%~dp0commands.txt"

set /p MORE_VLANS=Do you want to create another VLAN? (y/n): 
if /i "%MORE_VLANS%"=="y" goto configure_vlan
if /i "%MORE_VLANS%"=="n" goto check_interface
echo Invalid option. Please enter y or n.
pause
exit /b 1

:check_interface
set /p INTERFACE_CONFIG=Do you want to configure interface? (y/n): 
if /i "%INTERFACE_CONFIG%"=="y" goto configure_interface
if /i "%INTERFACE_CONFIG%"=="n" goto check_subinterface
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_interface
set /p INTERFACE_NAME=Interface designation (e.g., fa0/1, g0/0): 
if "%INTERFACE_NAME%"=="" goto error_interface_name

rem Add interface commands to file
(
    echo interface %INTERFACE_NAME%
    echo no shut
) >> "%~dp0commands.txt"

set /p SWITCHPORT_CONFIG=Do you want to configure switchport mode? (y/n): 
if /i "%SWITCHPORT_CONFIG%"=="y" goto configure_switchport
if /i "%SWITCHPORT_CONFIG%"=="n" goto ask_ip_config
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_switchport
set /p SWITCHPORT_MODE=Switchport mode - trunk or access? (t/a): 
if /i "%SWITCHPORT_MODE%"=="t" goto configure_trunk
if /i "%SWITCHPORT_MODE%"=="a" goto configure_access
echo Invalid option. Please enter t for trunk or a for access.
pause
exit /b 1

:configure_trunk
set TRUNK_VLANS=
set /p TRUNK_VLAN=Enter VLAN number for trunk: 
if "%TRUNK_VLAN%"=="" goto error_trunk_vlan
set TRUNK_VLANS=%TRUNK_VLAN%

:add_more_trunk_vlans
set /p MORE_TRUNK_VLANS=Do you want to add another VLAN to trunk? (y/n): 
if /i "%MORE_TRUNK_VLANS%"=="y" goto add_trunk_vlan
if /i "%MORE_TRUNK_VLANS%"=="n" goto finish_trunk
echo Invalid option. Please enter y or n.
pause
exit /b 1

:add_trunk_vlan
set /p TRUNK_VLAN=Enter VLAN number for trunk: 
if "%TRUNK_VLAN%"=="" goto error_trunk_vlan
set TRUNK_VLANS=%TRUNK_VLANS%,%TRUNK_VLAN%
goto add_more_trunk_vlans

:finish_trunk
(
    echo switchport mode trunk
    echo switchport trunk allowed vlan %TRUNK_VLANS%
) >> "%~dp0commands.txt"

set /p NATIVE_CONFIG=Do you want to configure Native VLAN? (y/n): 
if /i "%NATIVE_CONFIG%"=="y" goto configure_native
if /i "%NATIVE_CONFIG%"=="n" goto finish_interface
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_native
set /p NATIVE_VLAN=Native VLAN number: 
if "%NATIVE_VLAN%"=="" goto error_native_vlan
(
    echo switchport trunk native vlan %NATIVE_VLAN%
) >> "%~dp0commands.txt"
goto finish_interface

:configure_access
set /p ACCESS_VLAN=Access VLAN number: 
if "%ACCESS_VLAN%"=="" goto error_access_vlan
(
    echo switchport mode access
    echo switchport access vlan %ACCESS_VLAN%
) >> "%~dp0commands.txt"
goto finish_interface

:ask_ip_config
set /p IP_CONFIG=Do you want to configure IP address? (y/n): 
if /i "%IP_CONFIG%"=="y" goto configure_ip
if /i "%IP_CONFIG%"=="n" goto finish_interface
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_ip
set /p IP_ADDRESS=IP address: 
if "%IP_ADDRESS%"=="" goto error_ip_address

set /p SUBNET_MASK=Subnet mask: 
if "%SUBNET_MASK%"=="" goto error_subnet_mask

(
    echo ip address %IP_ADDRESS% %SUBNET_MASK%
) >> "%~dp0commands.txt"
goto finish_interface

:finish_interface
(
    echo exit
) >> "%~dp0commands.txt"

set /p MORE_INTERFACES=Do you want to configure another interface? (y/n): 
if /i "%MORE_INTERFACES%"=="y" goto configure_interface
if /i "%MORE_INTERFACES%"=="n" goto check_subinterface
echo Invalid option. Please enter y or n.
pause
exit /b 1

:check_subinterface
set /p SUBINTERFACE_CONFIG=Do you want to configure subinterfaces? (y/n): 
if /i "%SUBINTERFACE_CONFIG%"=="y" goto configure_subinterface
if /i "%SUBINTERFACE_CONFIG%"=="n" goto success
echo Invalid option. Please enter y or n.
pause
exit /b 1

:configure_subinterface
set /p PARENT_INTERFACE=On which interface do you want to create subinterface (e.g., g0/0): 
if "%PARENT_INTERFACE%"=="" goto error_parent_interface

rem Configure parent interface
(
    echo interface %PARENT_INTERFACE%
    echo no shut
    echo exit
) >> "%~dp0commands.txt"

:configure_subinterface_loop
set /p SUBINTERFACE_NUMBER=Subinterface number: 
if "%SUBINTERFACE_NUMBER%"=="" goto error_subinterface_number

set /p SUBINTERFACE_IP=IP address for subinterface: 
if "%SUBINTERFACE_IP%"=="" goto error_subinterface_ip

set /p SUBINTERFACE_MASK=Subnet mask for subinterface: 
if "%SUBINTERFACE_MASK%"=="" goto error_subinterface_mask

rem Add subinterface commands to file
(
    echo interface %PARENT_INTERFACE%.%SUBINTERFACE_NUMBER%
    echo encapsulation dot1q %SUBINTERFACE_NUMBER%
    echo ip address %SUBINTERFACE_IP% %SUBINTERFACE_MASK%
    echo exit
) >> "%~dp0commands.txt"

set /p MORE_SUBINTERFACES=Do you want to configure another subinterface on this interface? (y/n): 
if /i "%MORE_SUBINTERFACES%"=="y" goto configure_subinterface_loop
if /i "%MORE_SUBINTERFACES%"=="n" goto ask_another_parent
echo Invalid option. Please enter y or n.
pause
exit /b 1

:ask_another_parent
set /p ANOTHER_PARENT=Do you want to configure subinterfaces on another interface? (y/n): 
if /i "%ANOTHER_PARENT%"=="y" goto configure_subinterface
if /i "%ANOTHER_PARENT%"=="n" goto success
echo Invalid option. Please enter y or n.
pause
exit /b 1

:generate_basic
rem Generate basic commands without SSH
(
    echo enable
    echo conf t
    if /i "%BASIC_CONFIG%"=="y" (
        echo enable secret %EXECpass%
        echo hostname %HOSTNAME%
        echo line console 0
        echo password %CONSOLEpass%
        echo exit
    )
) > "%~dp0commands.txt"
goto check_subinterface

:error_hostname
echo No hostname was specified.
pause
exit /b 1

:error_exec
echo No password was specified.
pause
exit /b 1

:error_console
echo No password was specified.
pause
exit /b 1

:error_domain
echo No domain was specified.
pause
exit /b 1

:error_username
echo No username was specified.
pause
exit /b 1

:error_userpass
echo No password was specified.
pause
exit /b 1

:error_modulus
echo No modulus was specified.
pause
exit /b 1

:error_vlan_id
echo No VLAN number was specified.
pause
exit /b 1

:error_vlan_name
echo No VLAN name was specified.
pause
exit /b 1

:error_interface_name
echo No interface designation was specified.
pause
exit /b 1

:error_trunk_vlan
echo No VLAN number was specified for trunk.
pause
exit /b 1

:error_native_vlan
echo No Native VLAN number was specified.
pause
exit /b 1

:error_access_vlan
echo No Access VLAN number was specified.
pause
exit /b 1

:error_ip_address
echo No IP address was specified.
pause
exit /b 1

:error_subnet_mask
echo No subnet mask was specified.
pause
exit /b 1

:error_parent_interface
echo No parent interface was specified.
pause
exit /b 1

:error_subinterface_number
echo No subinterface number was specified.
pause
exit /b 1

:error_subinterface_ip
echo No IP address was specified for subinterface.
pause
exit /b 1

:error_subinterface_mask
echo No subnet mask was specified for subinterface.
pause
exit /b 1

:success
echo File has been created: "%~dp0commands.txt"
pause
