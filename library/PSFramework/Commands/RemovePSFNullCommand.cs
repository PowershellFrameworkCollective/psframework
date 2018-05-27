using System;
using System.Collections;
using System.Management.Automation;

namespace PSFramework.Commands
{
    /// <summary>
    /// Implements the Remove-PSFNull command
    /// </summary>
    [Cmdlet("Remove", "PSFNull")]
    public class RemovePSFNullCommand : Cmdlet
    {
        #region Parameter
        /// <summary>
        /// The objects to process
        /// </summary>
        [Parameter(ValueFromPipeline = true)]
        [AllowNull]
        [AllowEmptyString]
        [AllowEmptyCollection]
        public PSObject InputObject;

        /// <summary>
        /// Whether empty collections should be passed along
        /// </summary>
        [Parameter()]
        public SwitchParameter AllowEmptyCollections;

        /// <summary>
        /// Whether empty strings should be legal
        /// </summary>
        [Parameter()]
        public SwitchParameter AllowEmptyStrings;

        /// <summary>
        /// Whether the output should be enumerated
        /// </summary>
        [Parameter()]
        public SwitchParameter Enumerate;
        #endregion Parameter

        /// <summary>
        /// Process items as they are passed to the cmdlet
        /// </summary>
        protected override void ProcessRecord()
        {
            if (InputObject == null)
                return;

            //PSObject tempObject = InputObject as PSObject;

            if (!AllowEmptyStrings.IsPresent || !AllowEmptyStrings.ToBool())
            {
                string tempString = InputObject.BaseObject as string;
                if (tempString == "")
                    return;
            }

            if (!AllowEmptyCollections.IsPresent || !AllowEmptyCollections.ToBool())
            {
                ICollection tempCollection = InputObject.BaseObject as ICollection;
                if ((tempCollection != null) && (tempCollection.Count == 0))
                    return;
            }

            WriteObject(InputObject, Enumerate);
        }
    }
}
