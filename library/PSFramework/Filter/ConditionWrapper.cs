using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Filter
{
    internal class ConditionWrapper
    {
        internal string Name;
        internal string Module;
        Dictionary<Version, Condition> Conditions = new Dictionary<Version, Condition>();

        internal ConditionWrapper(Condition Condition)
        {
            Name = Condition.Name;
            Module = Condition.Module;
            Conditions[Condition.Version] = Condition;
        }

        internal Condition Get()
        {
            return Conditions[Conditions.Keys.OrderByDescending(o => o).First()];
        }
        internal Condition Get(Version Version)
        {
            return Conditions[Version];
        }
        internal List<Condition> List()
        {
            return new List<Condition>(Conditions.Values);
        }
        internal void Add(Condition Condition)
        {
            Conditions[Condition.Version] = Condition;
        }
    }
}
