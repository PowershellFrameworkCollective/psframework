namespace PSFramework.Filter
{
    /// <summary>
    /// What kind of condition is it?
    /// </summary>
    public enum ConditionType
    {
        /// <summary>
        /// The condition is static - its value needs only be processed once.
        /// </summary>
        Static,

        /// <summary>
        /// The condition is dynamic - its value may change and should be evaluated each time.
        /// May accept arguments.
        /// </summary>
        Dynamic
    }
}
