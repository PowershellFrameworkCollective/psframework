Describe "Testing the command XXX" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}
}