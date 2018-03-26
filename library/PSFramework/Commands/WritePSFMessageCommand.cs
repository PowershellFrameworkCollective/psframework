using PSFramework.Message;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Commands
{
    /// <summary>
    /// Cmdlet performing message handling and logging
    /// </summary>
    [Cmdlet("Write","PSFMessage")]
    public class WritePSFMessageCommand : PSCmdlet
    {
        #region Parameters
        [Parameter()]
        public MessageLevel Level = MessageLevel.Verbose;

        [Parameter(Mandatory = true, Position = 0)]
        public string Message;

        [Parameter()]
        public string[] Tag;

        [Parameter()]
        public string FunctionName;

        [Parameter()]
        public string ModuleName;

        [Parameter()]
        public string File;

        [Parameter()]
        public int Line;

        [Parameter()]
        public ErrorRecord[] ErrorRecord;

        [Parameter()]
        public Exception Exception;

        [Parameter()]
        public string Once;

        [Parameter()]
        public SwitchParameter OverrideExceptionMessage;

        [Parameter()]
        public object Target;

        [Parameter()]
        public bool EnableException;
        #endregion Parameters

        
    }
}
