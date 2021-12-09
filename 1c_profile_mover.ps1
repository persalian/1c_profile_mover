<#

    .SYNOPSIS
    Перенос каталога временных файлов 1С в другое место с созданием ссылок на него в профайле пользователя.
    
    .PARAMETER dist
    Указываем папку где будет создан профайл

    .parameter username
    Имя пользователя для которого создаются каталоги. Если пользователь не указан - используется имя текущего пользователя.

    .DESCRIPTION
    Скрипт создает в указаном каталоге dist папку с USERNAME\AppData\[Roaming|Local]\1C\1cv8
    В локальном профайле пользователя создаются символические ссылки на созданные каталоги. 

    Если изначально в профайле пользователя не было каталогов временных файлов 1с (1С раньше не запускалось), то создаются символьные ссылки на созданные каталоги в dist.
    Если в профайле пользователя каталоги временных файлов присуствуют, т.е 1с раньше запускалось, то создаются каталоги в dist и затем содердимое временых каталогов 1с переносится в созданные каталоги.
    Каталоги временных файлов 1С в профайле пользователя удаляются, и на их месте создаются символьные ссылки.

    Во времря работы скрипта, 1с у пользователя не должна работать.
    
    После запуска 1С в качестве каталога временых папок 1С будут использоваться созданные каталоги.

    .INPUTS
    Нет входящих объектов или данных

    .OUTPUTS
    Выводится строка с созданными каталогами в формате json

    .EXAMPLE
    PS> 1c_profile_mover -dist d:\1c_profiles

    .EXAMPLE
    PS> 1c_profile_mover -dist d:\1c_profiles -username user1

#>

param (
    [parameter(mandatory)] [string]$dist,
    [string] $username = "CURRENTUSER"
)



if($username -eq "CURRENTUSER"){
    $username = $env:USERNAME

}else{
    #throw "Использование имени пользователя $username не поддерживается"
    #exit -1
}


$src_local = 'c:\users\' + $username + '\AppData\Local\1C\1cv8'
$src_roaming = 'c:\users\' + $username + '\AppData\Roaming\1C\1cv8'

$dst_local = $dist + '\' + $username + '\AppData\Local\1C\1cv8'
$dst_roaming = $dist + '\' + $username + '\AppData\Roaming\1C\1cv8'

$old_profile = 'c:\users\' + $username
$new_profile = $dist + '\' + $username

<# 
проверим что целевые каталоги отсуствуют. если каталоги есть - 
удаляем старые и создаем новые пустые.
Проверяем исходные каталоги и проверяем что они не ссылки.
Если ссылки - удаляем
#>
if( test-path -Path $dst_local){
    
    # если каталоги есть
    Remove-Item -Recurse -Path $dst_local

}
if( Test-Path -Path $dst_roaming){
    
    # если каталоги есть
    Remove-Item -Recurse -Path $dst_roaming

}

if( Test-Path -Path $src_local) {
    if( .\junction64.exe $src_local -nobanner | select-string "JUNCTION" -Quiet ){
        Remove-Item $src_local -Force
        exit -1
    }
}

if( Test-Path -Path $src_roaming) {
    if( .\junction64.exe $src_roaming -nobanner | select-string "JUNCTION" -Quiet ){
        Remove-Item $src_roaming -Force
        exit -1
    }
}

# если исходные каталоги есть - данные переносим в целевые каталоги
# и создаем ссылки на целевые аталоги. Если исходных катлогов нет - просто создаем пустые 
# целевые каталоги и ссылки на них.

if(Test-Path -Path $src_local ){
    Move-Item -Path $src_local -Destination $dst_local
}else{
    New-Item -ItemType Directory -Path $dst_local
}
#New-Item -ItemType Junction -Path $src_local -Value $dst_local
.\junction64.exe -nobanner $src_local $dst_local 


if(Test-Path -Path $src_roaming ){
    Move-Item -Path $src_roaming -Destination $dst_roaming
}else{
    New-Item -ItemType Directory -Path $dst_roaming
}
#New-Item -ItemType Junction -Path $src_roaming -Value $dst_roaming
.\junction64.exe -nobanner $src_roaming $dst_roaming 

<# 
добавляем права на изменение для пользователя на папку с новым профайлом
#>
$acl = Get-Acl($new_profile)
$Rule=new-object System.Security.AccessControl.FileSystemAccessRule $username,"Modify, Synchronize","ContainerInherit", "None","allow"
$acl.AddAccessRule($Rule)
$acl | set-acl ($new_profile)

