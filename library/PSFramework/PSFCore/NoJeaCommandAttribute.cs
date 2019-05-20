using System;

namespace PSFramework.PSFCore
{
    /// <summary>
    /// Decorator attribute declaring a command in its entirety unsafe for making publicly available in JEA
    /// </summary>
    [AttributeUsage(AttributeTargets.All)]
    public class NoJeaCommandAttribute : Attribute
    {
    }
}
