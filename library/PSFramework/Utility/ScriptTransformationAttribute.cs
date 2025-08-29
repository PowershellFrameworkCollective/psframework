using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// Allow custom argument transformation logic defined in script
    /// </summary>
    public class ScriptTransformationAttribute : ArgumentTransformationAttribute
    {
        /// <summary>
        /// List of registered conversion logics
        /// </summary>
        public static ConcurrentDictionary<string, PsfScriptBlock> Conversions = new ConcurrentDictionary<string, PsfScriptBlock>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Name of the conversion logic to use
        /// </summary>
        public string Name;

        /// <summary>
        /// The target type we try to generate
        /// </summary>
        public Type TargetType;

        /// <summary>
        /// Converts input to output
        /// </summary>
        /// <param name="engineIntrinsics"></param>
        /// <param name="inputData"></param>
        /// <returns></returns>
        public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
        {
            if (inputData == null)
                throw new ArgumentNullException();

            bool foundScript = Conversions.ContainsKey(Name);
            Exception failure = null;
            if (foundScript)
            {
                try {
                    Collection<PSObject> result = Conversions[Name].InvokeGlobal(inputData);
                    if (result.Count() == 0 || result[0] == null)
                        throw new InvalidOperationException($"Conversion Script {Name} failed to return anything! Input: {inputData}");
                    if (result[0].BaseObject.GetType() != TargetType && !TargetType.IsAssignableFrom(result[0].BaseObject.GetType()))
                        throw new InvalidOperationException($"Conversion Script {Name} converted {inputData} to {result[0].BaseObject.GetType().FullName}, rather than {TargetType.FullName}");
                    return result[0];
                }
                catch (Exception e) {  failure = e; }
            }
            try
            {
                return LanguagePrimitives.ConvertTo(inputData, TargetType);
            }
            catch
            {
                if (failure != null)
                {
                    if (failure is TargetInvocationException && failure.InnerException != null)
                        throw failure.InnerException;

                    throw failure;
                }
                throw;
            }
        }

        /// <summary>
        /// Creates a new and awesome transformation attribute
        /// </summary>
        /// <param name="Name"></param>
        /// <param name="TargetType"></param>
        public ScriptTransformationAttribute(string Name, Type TargetType)
        {
            this.Name = Name;
            this.TargetType = TargetType;
        }
    }
}
