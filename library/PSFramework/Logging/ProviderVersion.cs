namespace PSFramework.Logging
{
    /// <summary>
    /// The generation of the Logging Provider Type
    /// </summary>
    public enum ProviderVersion
    {
        /// <summary>
        /// The initial, now legacy version of logging providers, where all providers share the same variable scope.
        /// </summary>
        Version_1 = 1,

        /// <summary>
        /// Generation 2 logging provider, where each provider is handled as a dynamically created module, properly isolating resource from each other.
        /// </summary>
        Version_2 = 2
    }
}
