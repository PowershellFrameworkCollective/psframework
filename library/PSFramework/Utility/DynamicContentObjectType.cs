namespace PSFramework.Utility
{
    /// <summary>
    /// The kind of dynamic content object was specified
    /// </summary>
    public enum DynamicContentObjectType
    {
        /// <summary>
        /// A regular object was requested
        /// </summary>
        Common,

        /// <summary>
        /// A queue was requested
        /// </summary>
        Queue,

        /// <summary>
        /// A list was requested
        /// </summary>
        List,

        /// <summary>
        /// A stack was requested
        /// </summary>
        Stack,

        /// <summary>
        /// A dictionary was requested
        /// </summary>
        Dictionary
    }
}
