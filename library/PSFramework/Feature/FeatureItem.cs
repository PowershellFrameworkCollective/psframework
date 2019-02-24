namespace PSFramework.Feature
{
    /// <summary>
    /// Represents a feature a module offers
    /// </summary>
    public class FeatureItem
    {
        /// <summary>
        /// The name of the feature
        /// </summary>
        public string Name;

        /// <summary>
        /// The owning module
        /// </summary>
        public string Owner;

        /// <summary>
        /// Whether the feature can be set globally
        /// </summary>
        public bool Global;

        /// <summary>
        /// Whether the feature can be overridden on a per module bases.
        /// </summary>
        public bool ModuleSpecific;

        /// <summary>
        /// The general description of the feature for human consumption
        /// </summary>
        public string Description;

        /// <summary>
        /// Creates an empty feature
        /// </summary>
        public FeatureItem()
        {

        }

        /// <summary>
        /// Creates a feature all fileld out.
        /// </summary>
        /// <param name="Name"></param>
        /// <param name="Owner"></param>
        /// <param name="Global"></param>
        /// <param name="ModuleSpecific"></param>
        /// <param name="Description"></param>
        public FeatureItem(string Name, string Owner, bool Global, bool ModuleSpecific, string Description)
        {
            this.Name = Name;
            this.Owner = Owner;
            this.Global = Global;
            this.ModuleSpecific = ModuleSpecific;
            this.Description = Description;
        }
    }
}
