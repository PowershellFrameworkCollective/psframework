Describe "Testing the command XXX" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}
}