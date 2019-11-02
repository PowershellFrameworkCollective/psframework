using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// Tries to convert input type into the target type, using PowerShell type coercion.
    /// Implemented to have a bool parameter accept a switch value.
    /// </summary>
    public class TypeTransformationAttribute : ArgumentTransformationAttribute
    {
        /// <summary>
        /// The type to convert to
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
            try
            {
                return LanguagePrimitives.ConvertTo(inputData, TargetType);
            }
            catch
            {
                throw;
            }
        }

        /// <summary>
        /// Creates the basic attribute specifying the target type
        /// </summary>
        /// <param name="TargetType">The type to convert to</param>
        public TypeTransformationAttribute(Type TargetType)
        {
            this.TargetType = TargetType;
        }
    }
}
