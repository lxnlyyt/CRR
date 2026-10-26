# Shared list of game scripts: where each source file lives in the DataModel.
# Parents must be listed before their children (the server Script before its modules).
$GameSources = @(
    @{ Path = 'src/shared/Config.luau';        Parent = 'ReplicatedStorage.MonsterEgg';                           Name = 'Config';           Class = 'ModuleScript' },
    @{ Path = 'src/shared/Style.luau';         Parent = 'ReplicatedStorage.MonsterEgg';                           Name = 'Style';            Class = 'ModuleScript' },
    @{ Path = 'src/shared/Eggs.luau';          Parent = 'ReplicatedStorage.MonsterEgg';                           Name = 'Eggs';             Class = 'ModuleScript' },
    @{ Path = 'src/shared/Monsters.luau';      Parent = 'ReplicatedStorage.MonsterEgg';                           Name = 'Monsters';         Class = 'ModuleScript' },
    @{ Path = 'src/shared/World.luau';         Parent = 'ReplicatedStorage.MonsterEgg';                           Name = 'World';            Class = 'ModuleScript' },
    @{ Path = 'src/server/init.server.luau';   Parent = 'ServerScriptService';                                    Name = 'MonsterEggServer'; Class = 'Script' },
    @{ Path = 'src/server/Data.luau';          Parent = 'ServerScriptService.MonsterEggServer';                   Name = 'Data';             Class = 'ModuleScript' },
    @{ Path = 'src/server/Guardians.luau';     Parent = 'ServerScriptService.MonsterEggServer';                   Name = 'Guardians';        Class = 'ModuleScript' },
    @{ Path = 'src/client/init.client.luau';   Parent = 'StarterPlayer.StarterPlayerScripts';                     Name = 'MonsterEggClient'; Class = 'LocalScript' },
    @{ Path = 'src/client/Hud.luau';           Parent = 'StarterPlayer.StarterPlayerScripts.MonsterEggClient';    Name = 'Hud';              Class = 'ModuleScript' },
    @{ Path = 'src/client/Fx.luau';            Parent = 'StarterPlayer.StarterPlayerScripts.MonsterEggClient';    Name = 'Fx';               Class = 'ModuleScript' }
)
