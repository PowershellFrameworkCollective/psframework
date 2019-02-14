using System.Management.Automation;

namespace PSFramework.Commands
{
    /// <summary>
    /// Implements the Test-PSFShouldProcess command
    /// </summary>
    [Cmdlet("Test", "PSFShouldProcess", SupportsShouldProcess = true, DefaultParameterSetName = "Message")]
    public class TestPSFShouldProcessCommand : PSCmdlet
    {
        /// <summary>
        /// The target object to process
        /// </summary>
        [Parameter(Mandatory = true)]
        public string Target;

        /// <summary>
        /// Description of the action to perform
        /// </summary>
        [Parameter(Mandatory = true, ParameterSetName = "Message")]
        public string Action;

        /// <summary>
        /// A string to use localized message for the prompt
        /// </summary>
        [Parameter(Mandatory = true, ParameterSetName = "String")]
        public string ActionString;

        /// <summary>
        /// Values to format into the localized string
        /// </summary>
        public object[] ActionStringValues = new object[10];

        /// <summary>
        /// The PSCmdlet object of the calling command
        /// </summary>
        [Parameter()]
        public PSCmdlet PSCmdlet;

        /// <summary>
        /// Private copy of the specified or found cmdlet object
        /// </summary>
        private PSCmdlet _PSCmdlet;

        /// <summary>
        /// THe resolved action string to display
        /// </summary>
        private string _Action
        {
            get
            {
                if (!string.IsNullOrEmpty(Action))
                    return Action;

                return string.Format(Localization.LocalizationHost.ReadLog(ActionString), ActionStringValues);
            }
        }

        /// <summary>
        /// Clarifies Cmdlet object during begin
        /// </summary>
        protected override void BeginProcessing()
        {
            if (PSCmdlet == null)
                _PSCmdlet = (PSCmdlet)GetVariableValue("PSCmdlet");
            else
                _PSCmdlet = PSCmdlet;
        }

        /// <summary>
        /// Perform the query
        /// </summary>
        protected override void ProcessRecord()
        {
            WriteObject(_PSCmdlet.ShouldProcess(Target, _Action));
        }
    }
}
