namespace PSFramework.License
{
    /// <summary>
    /// What kind of product is being licensed
    /// </summary>
    public enum ProductType
    {
        /// <summary>
        /// The product is a PowerShell module
        /// </summary>
        Module = 1,

        /// <summary>
        /// The Product is a Script of any kind
        /// </summary>
        Script = 2,

        /// <summary>
        /// The Product is a library, bringing functionality to the Shell
        /// </summary>
        Library = 3,

        /// <summary>
        /// The Product is a standalone application, that happens to utilize PowerShell
        /// </summary>
        Application = 4,

        /// <summary>
        /// The Product is anything other than the default types
        /// </summary>
        Other = 5,
    }
}