using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Filter
{
    internal class ConditionSetWrapper
    {
        internal string Name;
        internal string Module;
        Dictionary<Version, ConditionSet> ConditionSets = new Dictionary<Version, ConditionSet>();

        internal ConditionSetWrapper(ConditionSet ConditionSet)
        {
            Name = ConditionSet.Name;
            Module = ConditionSet.Module;
            ConditionSets[ConditionSet.Version] = ConditionSet;
        }

        internal ConditionSet Get()
        {
            return ConditionSets[ConditionSets.Keys.OrderByDescending(o => o).First()];
        }
        internal ConditionSet Get(Version Version)
        {
            return ConditionSets[Version];
        }
        internal List<ConditionSet> List()
        {
            return new List<ConditionSet>(ConditionSets.Values);
        }

        internal void Add(ConditionSet ConditionSet)
        {
            ConditionSets[ConditionSet.Version] = ConditionSet;
        }
    }
}
