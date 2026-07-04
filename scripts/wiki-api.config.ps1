@{
    WikiBaseUrl = 'https://github.com/AmyJeanes/world-portals/wiki'
    Categories = @(
        @{ Title = 'False Worlds Reference'; File = 'False-Worlds-Reference'; Roots = @('worldportals_false_world') }
        @{ Title = 'Functions Reference';    File = 'Functions-Reference';    Kind = 'functions'; Class = 'wp' }
        @{ Title = 'linked_portal_door';     File = 'linked_portal_door';     Kind = 'functions'; Class = 'linked_portal_door'; Source = 'lua/entities/linked_portal_door'; NetworkVars = $true }
        @{ Title = 'Hooks Reference';        File = 'Hooks-Reference';        Kind = 'hooks' }
        @{ Title = 'ConVars Reference';      File = 'ConVars-Reference';      Kind = 'convars' }
    )
    OwnedPrefix = @('worldportals_')
}
