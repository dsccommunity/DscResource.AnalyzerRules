@{
    # Set up a mini virtual environment...
    PSDependOptions      = @{
        AddToPath  = $True
        Target     = 'output\RequiredModules'
        Parameters = @{
        }
    }

    invokeBuild          = 'latest'
    PSScriptAnalyzer     = 'latest'
    pester               = '4.10.1'
    Plaster              = 'latest'
    ModuleBuilder        = 'latest'
    ChangelogManagement  = 'latest'
    Sampler              = 'latest'

    #required for DSC authoring
    # xDscResourceDesigner = 'latest'
}
