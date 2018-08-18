using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// List of data items New-PSFSupportPackage will export
    /// </summary>
    [Flags]
    public enum SupportData
    {
        /// <summary>
        /// Nothing. Be stingy, will ya?!
        /// </summary>
        None = 0,

        /// <summary>
        /// All messages logged to the PSFramework that are still in memory
        /// </summary>
        Message = 1,

        /// <summary>
        /// All error records logged to the PSFramework that are still in memory
        /// </summary>
        ErrorMessage = 2,

        /// <summary>
        /// A "screenshot" record of the console buffer
        /// </summary>
        Screenshot = 4,

        /// <summary>
        /// Data about the OS, gathered from WMI
        /// </summary>
        OperatingSystem = 8,

        /// <summary>
        /// Data about the processors, gathered from WMI
        /// </summary>
        CPU = 16,

        /// <summary>
        /// Data about the ram, gathered from WMI
        /// </summary>
        Ram = 32,

        /// <summary>
        /// Data about the PowerShell version
        /// </summary>
        PSVersion = 64,

        /// <summary>
        /// Input history
        /// </summary>
        History = 128,

        /// <summary>
        /// List of modules that are imported
        /// </summary>
        Module = 256,

        /// <summary>
        /// List of snapins that are loaded
        /// </summary>
        SnapIns = 512,

        /// <summary>
        /// List of assmeblies that have been imported
        /// </summary>
        Assemblies = 1024,

        /// <summary>
        /// All exception records written to the global $error variable
        /// </summary>
        Exceptions = 2048,

        /// <summary>
        /// Data provided by foreign modules
        /// </summary>
        ExtensionData = 4096,


        /// <summary>
        /// All data ill be exported
        /// </summary>
        All = 8191,

        /// <summary>
        /// PSFramework messages
        /// </summary>
        Messages = 3,

        /// <summary>
        /// The most critical error data, including: Messages, error messages, error records and PSVersion
        /// </summary>
        Critical = 1 + 2 + 64 + 2048,

        /// <summary>
        /// PSVersion, Modules, Snapins and Assemblies
        /// </summary>
        PSResource = 64 + 256 + 512 + 1024,

        /// <summary>
        /// Operating System, CPU &amp; RAM
        /// </summary>
        Environment = 8 + 16 + 32
    }
}
