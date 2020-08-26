using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Reflection;

namespace PSFramework.Utility
{
    /// <summary>
    /// Transformation attribute that can convert PSObjects or hashtables to the target type, so long as it has an empty constructor
    /// </summary>
    public class DynamicTransformationAttribute : ArgumentTransformationAttribute
    {
        /// <summary>
        /// The type to convert to
        /// </summary>
        public Type TargetType;

        /// <summary>
        /// Whether a null object is acceptable as input
        /// </summary>
        public bool AllowNull;

        /// <summary>
        /// List of properties that must be specified on the input object
        /// </summary>
        public string[] RequiredProperties = new string[0];

        /// <summary>
        /// Converts input to output
        /// </summary>
        /// <param name="engineIntrinsics"></param>
        /// <param name="inputData"></param>
        /// <returns></returns>
        public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        {
            if (inputData == null)
            {
                if (AllowNull)
                    return null;
                else
                    throw new ArgumentNullException();
            }

            try { return LanguagePrimitives.ConvertTo(inputData, TargetType); }
            catch { }

            ConstructorInfo constructor = TargetType.GetConstructors().Where(c => c.GetParameters().Length == 0).FirstOrDefault();
            if (constructor == null)
                throw new InvalidOperationException($"Cannot convert to {TargetType.FullName} - no suitable constructor exists for dynamic input conversion");

            PSObject targetObject = PSObject.AsPSObject(constructor.Invoke(null));

            List<string> properties = new List<string>();
            if (typeof(IDictionary).IsAssignableFrom(inputData.GetType()))
            {
                IDictionary dictionary = (IDictionary)inputData;

                foreach (string key in dictionary.Keys)
                {
                    if (targetObject.Properties.Where(p => p.Name == key && p.IsSettable).Count() > 0)
                    {
                        try
                        {
                            targetObject.Properties[key].Value = dictionary[key];
                            properties.Add(key);
                        }
                        catch { }
                    }
                }
            }
            else
            {
                PSObject sourceObject = PSObject.AsPSObject(inputData);
                foreach (PSPropertyInfo property in sourceObject.Properties)
                {
                    if (targetObject.Properties.Where(p => p.Name == property.Name && p.IsSettable).Count() > 0)
                    {
                        try
                        {
                            targetObject.Properties[property.Name].Value = property.Value;
                            properties.Add(property.Name);
                        }
                        catch { }
                    }
                }
            }

            if (properties.Count == 0)
                throw new ArgumentException($"Failed to convert {inputData} to {TargetType.FullName}!");

            string[] tempArr = RequiredProperties.Where(p => !properties.Contains(p)).ToArray();
            if (tempArr.Length > 0)
                throw new ArgumentException($"Failed to convert {inputData} to {TargetType.FullName}! Missing required properties: {string.Join(",", tempArr)}");

            return targetObject;
        }

        /// <summary>
        /// Creates the basic attribute specifying the target type
        /// </summary>
        /// <param name="TargetType">The type to convert to</param>
        /// <param name="RequiredProperties">Properties to require</param>
        public DynamicTransformationAttribute(Type TargetType, params string[] RequiredProperties)
        {
            this.TargetType = TargetType;
            if (RequiredProperties != null)
                this.RequiredProperties = RequiredProperties;
        }
    }
}
