namespace PSFramework.Configuration
{
    /// <summary>
    /// A setting that has been persisted on the computer.
    /// </summary>
    public class PersistedConfig
    {
        /// <summary>
        /// The full name of the setting
        /// </summary>
        public string FullName;

        /// <summary>
        /// The scope it has been persisted to
        /// </summary>
        public ConfigScope Scope;

        /// <summary>
        /// The value of the setting
        /// </summary>
        public object Value;
    }
}
