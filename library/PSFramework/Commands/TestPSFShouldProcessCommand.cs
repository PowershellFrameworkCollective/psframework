using System.Management.Automation;

namespace PSFramework.Commands
{
    /// <summary>
    /// Implements the Test-PSFShouldProcess command
    /// </summary>
    [Cmdlet("Test", "PSFShouldProcess", SupportsShouldProcess = true)]
    public class TestPSFShouldProcessCommand : Cmdlet
    {
        /// <summary>
        /// The PSCmdlet object of the calling command
        /// </summary>
        [Parameter(Mandatory = true)]
        public PSCmdlet PSCmdlet;

        /// <summary>
        /// The target object to process
        /// </summary>
        [Parameter(Mandatory = true)]
        public string Target;

        /// <summary>
        /// Description of the action to perform
        /// </summary>
        [Parameter(Mandatory = true)]
        public string Action;

        /// <summary>
        /// Perform the query
        /// </summary>
        protected override void ProcessRecord()
        {
            WriteObject(PSCmdlet.ShouldProcess(Target, Action));
        }
    }
}
