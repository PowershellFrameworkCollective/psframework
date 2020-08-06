namespace PSFramework.Logging
{
    /// <summary>
    /// The data format to log to in the logfile logging provider
    /// </summary>
    public enum LogFileFileType
    {
        /// <summary>
        /// Write as comma separated value
        /// </summary>
        Csv,

        /// <summary>
        /// Write as Html fragment
        /// </summary>
        Html,

        /// <summary>
        /// Write as Json fragment
        /// </summary>
        Json,

        /// <summary>
        /// Write as Xml fragment
        /// </summary>
        Xml,

        /// <summary>
        /// Write as CMTrace compatible entry
        /// </summary>
        CMTrace
    }
}
