using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.PSFCore
{
    /// <summary>
    /// Class containing static settings and values used to globally handle things
    /// </summary>
    public static class PSFCoreHost
    {
        /// <summary>
        /// Whether the current console is in unattended mode
        /// </summary>
        public static bool Unattended = false;

        /// <summary>
        /// The path to where the module was imported from
        /// </summary>
        public static string ModuleRoot
        {
            get { return _ModuleRoot; }
            set
            {
                if (String.IsNullOrEmpty(_ModuleRoot))
                    _ModuleRoot = value;
            }
        }
        private static string _ModuleRoot;

        /// <summary>
        /// Initializes the PSFramework library.
        /// Required for some components to work correctly.
        /// </summary>
        public static void Initialize()
        {
            if (_Initialized)
                return;
            _Initialized = true;

            Runspace.RunspaceHost.StartRbvTimer();
            // Initialization logic goes here
        }
        private static bool _Initialized = false;

        /// <summary>
        /// Reverses the initialization of the PSFramework library.
        /// Should be called when destroying the main runspace
        /// </summary>
        public static void Uninitialize()
        {
            if (!_Initialized)
                return;

            // De-Initiialization logic goes here
            Runspace.RunspaceHost.StopRbvTimer();

            _Initialized = false;
        }

        #region Debug Mode
        /// <summary>
        /// The master switch to enable debug mode.
        /// </summary>
        public static bool DebugMode
        {
            get { return _DebugMode; }
            set
            {
                DebugData dummy;
                _DebugMode = value;
                if (!value)
                    while (!DebugData.IsEmpty)
                        DebugData.TryDequeue(out dummy);
            }
        }
        private static bool _DebugMode = false;

        /// <summary>
        /// Whether to write debug messages to the screen
        /// </summary>
        public static bool VerboseDebug = false;

        /// <summary>
        /// The total capacity of the debug queue
        /// </summary>
        public static int DebugQueueSize
        {
            get { return _DebugQueueSize; }
            set
            {
                _DebugQueueSize = value;
                DebugData.Size = value;
            }
        }
        private static int _DebugQueueSize = 256;

        /// <summary>
        /// Write a debug message
        /// </summary>
        /// <param name="Label">The label to apply to the data</param>
        /// <param name="Data">The data to write</param>
        public static void WriteDebug(string Label, object Data)
        {
            if (!DebugMode)
                return;

            DebugData.Enqueue(new DebugData(Label, Data));
            if (VerboseDebug)
                Console.WriteLine($"{DateTime.Now.ToString("HH:mm:ss.fff")} : {Label}");
        }

        /// <summary>
        /// The data storage containing the debug messages.
        /// </summary>
        public static readonly Utility.LimitedConcurrentQueue<DebugData> DebugData = new Utility.LimitedConcurrentQueue<DebugData>(DebugQueueSize);
        #endregion Debug Mode
    }
}
