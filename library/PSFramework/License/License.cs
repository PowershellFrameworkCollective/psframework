using System;

namespace PSFramework.License
{
    /// <summary>
    /// Contains license information for a single product
    /// </summary>
    [Serializable]
    public class License
    {
        /// <summary>
        /// The name of the product the license is for.
        /// </summary>
        public string Product;

        /// <summary>
        /// Who made the license product?
        /// </summary>
        public string Manufacturer;

        /// <summary>
        /// The version of the product covered by the license.
        /// </summary>
        public Version ProductVersion;

        /// <summary>
        /// The type of product the licensed product is.
        /// </summary>
        public ProductType ProductType;

        /// <summary>
        /// The name of the license. Useful for the usual public licenses.
        /// </summary>
        public string LicenseName;

        /// <summary>
        /// The version of the license. Useful for the usual public licenses.
        /// </summary>
        public Version LicenseVersion;

        /// <summary>
        /// When was the product licensed with the specified license.
        /// </summary>
        public DateTime LicenseDate;

        /// <summary>
        /// The type of the license. This allows filtering licenses by their limitations.
        /// </summary>
        public LicenseType LicenseType;

        /// <summary>
        /// The full license text for the pleasure of the reader.
        /// </summary>
        public string LicenseText;

        /// <summary>
        /// Add some desription to how it is used.
        /// </summary>
        public string Description;

        /// <summary>
        /// A parent license to indicate a product used within a product.
        /// </summary>
        public License Parent;

        /// <summary>
        /// The default string representation of the license object
        /// </summary>
        /// <returns>The default string representation of the license object</returns>
        public override string ToString()
        {
            return $"{Product} {ProductVersion} ({LicenseName})";
        }
    }
}