namespace PSFramework.Parameter
{
    /// <summary>
    /// List of available parameter classes
    /// </summary>
    public enum ParameterClasses
    {
        /// <summary>
        /// The computer parameter class allows easily targeting a computer
        /// </summary>
        Computer,

        /// <summary>
        /// The datetime parameter class allows for an easy way to specify a datetime
        /// </summary>
        DateTime,

        /// <summary>
        /// The timespan parameter class allows for an easy way to specify a timespan
        /// </summary>
        TimeSpan,

        /// <summary>
        /// The encoding parameter class allows to consistently accept encodings as input.
        /// </summary>
        Encoding,

        /// <summary>
        /// The set of path parameter classes allow to resolve file system path designations into absolute paths
        /// </summary>
        Path,
    }
}
