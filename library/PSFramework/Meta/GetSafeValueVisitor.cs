using System;
using System.Collections;
using System.IO;
using System.Linq;
using System.Management.Automation.Language;

namespace PSFramework.Meta
{
    /*
     * This implementation retrieves the safe value without directly calling the compiler
     * except in the case of handling the unary operator
     * ExecutionContext is provided to ensure we can resolve variables
     */
    internal class GetSafeValueVisitor : ICustomAstVisitor
    {
        internal enum SafeValueContext
        {
            Default,
            GetPowerShell,
            ModuleAnalysis
        }

        // future proofing
        private GetSafeValueVisitor() { }

        public static object GetSafeValue(Ast ast, ExecutionContext context, SafeValueContext safeValueContext)
        {
            s_context = context;
            if (IsSafeValueVisitor.IsAstSafe(ast, safeValueContext))
            {
                return ast.Accept(new GetSafeValueVisitor());
            }

            if (safeValueContext == SafeValueContext.ModuleAnalysis)
            {
                return null;
            }

            throw PSTraceSource.NewArgumentException("ast");
        }

        private static ExecutionContext s_context;

        public object VisitErrorStatement(ErrorStatementAst errorStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitErrorExpression(ErrorExpressionAst errorExpressionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitScriptBlock(ScriptBlockAst scriptBlockAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitParamBlock(ParamBlockAst paramBlockAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitNamedBlock(NamedBlockAst namedBlockAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitTypeConstraint(TypeConstraintAst typeConstraintAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitAttribute(AttributeAst attributeAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitNamedAttributeArgument(NamedAttributeArgumentAst namedAttributeArgumentAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitParameter(ParameterAst parameterAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitFunctionDefinition(FunctionDefinitionAst functionDefinitionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitIfStatement(IfStatementAst ifStmtAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitTrap(TrapStatementAst trapStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitSwitchStatement(SwitchStatementAst switchStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitDataStatement(DataStatementAst dataStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitForEachStatement(ForEachStatementAst forEachStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitDoWhileStatement(DoWhileStatementAst doWhileStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitForStatement(ForStatementAst forStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitWhileStatement(WhileStatementAst whileStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitCatchClause(CatchClauseAst catchClauseAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitTryStatement(TryStatementAst tryStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitBreakStatement(BreakStatementAst breakStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitContinueStatement(ContinueStatementAst continueStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitReturnStatement(ReturnStatementAst returnStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitExitStatement(ExitStatementAst exitStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitThrowStatement(ThrowStatementAst throwStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitDoUntilStatement(DoUntilStatementAst doUntilStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitAssignmentStatement(AssignmentStatementAst assignmentStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitCommand(CommandAst commandAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitCommandExpression(CommandExpressionAst commandExpressionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitCommandParameter(CommandParameterAst commandParameterAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitFileRedirection(FileRedirectionAst fileRedirectionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitMergingRedirection(MergingRedirectionAst mergingRedirectionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitAttributedExpression(AttributedExpressionAst attributedExpressionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitBlockStatement(BlockStatementAst blockStatementAst) { throw PSTraceSource.NewArgumentException("ast"); }

        public object VisitInvokeMemberExpression(InvokeMemberExpressionAst invokeMemberExpressionAst) { throw PSTraceSource.NewArgumentException("ast"); }

        //
        // This is similar to logic used deep in the engine for slicing something that can be sliced
        // It's recreated here because there isn't really a simple API which can be called for this case.
        // this can throw, but there really isn't useful information we can add, as the
        // offending expression will be presented in the case of any failure
        //
        private object GetSingleValueFromTarget(object target, object index)
        {
            var targetString = target as string;
            if (targetString != null)
            {
                var offset = (int)index;
                if (Math.Abs(offset) >= targetString.Length)
                {
                    return null;
                }

                return offset >= 0 ? targetString[offset] : targetString[targetString.Length + offset];
            }

            var targetArray = target as object[];
            if (targetArray != null)
            {
                // this can throw, that just gets percolated back
                var offset = (int)index;
                if (Math.Abs(offset) >= targetArray.Length)
                {
                    return null;
                }

                return offset >= 0 ? targetArray[offset] : targetArray[targetArray.Length + offset];
            }

            var targetHashtable = target as Hashtable;
            if (targetHashtable != null)
            {
                return targetHashtable[index];
            }
            // The actual exception doesn't really matter because the caller in ScriptBlockToPowerShell
            // will present the user with the offending script segment
            throw new Exception();
        }

        private object GetIndexedValueFromTarget(object target, object index)
        {
            var indexArray = index as object[];
            return indexArray != null ? ((object[])indexArray).Select(i => GetSingleValueFromTarget(target, i)).ToArray() : GetSingleValueFromTarget(target, index);
        }

        public object VisitIndexExpression(IndexExpressionAst indexExpressionAst)
        {
            // Get the value of the index and value and call the compiler
            var index = indexExpressionAst.Index.Accept(this);
            var target = indexExpressionAst.Target.Accept(this);
            if (index == null || target == null)
            {
                throw new ArgumentNullException("indexExpressionAst");
            }

            return GetIndexedValueFromTarget(target, index);
        }

        public object VisitExpandableStringExpression(ExpandableStringExpressionAst expandableStringExpressionAst)
        {
            object[] safeValues = new object[expandableStringExpressionAst.NestedExpressions.Count];
            // retrieve OFS, and if it doesn't exist set it to space
            string ofs = null;
            if (s_context != null)
            {
                ofs = s_context.SessionState.PSVariable.GetValue("OFS") as string;
            }

            if (ofs == null)
            {
                ofs = " ";
            }

            for (int offset = 0; offset < safeValues.Length; offset++)
            {
                var result = expandableStringExpressionAst.NestedExpressions[offset].Accept(this);
                // depending on the nested expression we may retrieve a variable, or even need to
                // execute a sub-expression. The result of which may be returned
                // as a scalar, array or nested array. If the unwrap of first array doesn't contain a nested
                // array we can then pass it to string.Join. If it *does* contain an array,
                // we need to unwrap the inner array and pass *that* to string.Join.
                //
                // This means we get the same answer with GetPowerShell() as in the command-line
                // { echo "abc $true $(1) $(2,3) def" }.Invoke() gives the same answer as
                // { echo "abc $true $(1) $(2,3) def" }.GetPowerShell().Invoke()
                // abc True 1 2 3 def
                // as does { echo "abc $true $(1) $(@(1,2),@(3,4)) def"
                // which is
                // abc True 1 System.Object[] System.Object[] def
                // fortunately, at this point, we're dealing with strings, so whatever the result
                // from the ToString method of the array (or scalar) elements, that's symmetrical with
                // a standard scriptblock invocation behavior
                var resultArray = result as object[];

                // In this environment, we can't use $OFS as we might expect. Retrieving OFS
                // might possibly leak server side info which we don't want, so we'll
                // assign ' ' as our OFS for purposes of GetPowerShell
                // Also, this will not call any script implementations of ToString (ala types.clixml)
                // This *will* result in a different result in those cases. However, to execute some
                // arbitrary script at this stage would be opening ourselves up to an attack
                if (resultArray != null)
                {
                    object[] subExpressionResult = new object[resultArray.Length];
                    for (int subExpressionOffset = 0;
                        subExpressionOffset < subExpressionResult.Length;
                        subExpressionOffset++)
                    {
                        // check to see if there is an array in our array,
                        object[] subResult = resultArray[subExpressionOffset] as object[];
                        if (subResult != null)
                        {
                            subExpressionResult[subExpressionOffset] = string.Join(ofs, subResult);
                        }
                        else // it is a scalar, so we can just add it to our collections
                        {
                            subExpressionResult[subExpressionOffset] = resultArray[subExpressionOffset];
                        }
                    }

                    safeValues[offset] = string.Join(ofs, subExpressionResult);
                }
                else
                {
                    safeValues[offset] = result;
                }
            }

            return StringUtil.Format(expandableStringExpressionAst.FormatExpression, safeValues);
        }

        public object VisitStatementBlock(StatementBlockAst statementBlockAst)
        {
            ArrayList statementList = new ArrayList();
            foreach (var statement in statementBlockAst.Statements)
            {
                if (statement != null)
                {
                    var obj = statement.Accept(this);
                    var enumerator = LanguagePrimitives.GetEnumerator(obj);
                    if (enumerator != null)
                    {
                        while (enumerator.MoveNext())
                        {
                            statementList.Add(enumerator.Current);
                        }
                    }
                    else
                    {
                        statementList.Add(obj);
                    }
                }
                else
                {
                    throw PSTraceSource.NewArgumentException("ast");
                }
            }

            return statementList.ToArray();
        }

        public object VisitPipeline(PipelineAst pipelineAst)
        {
            var expr = pipelineAst.GetPureExpression();
            if (expr != null)
            {
                return expr.Accept(this);
            }

            throw PSTraceSource.NewArgumentException("ast");
        }

        public object VisitBinaryExpression(BinaryExpressionAst binaryExpressionAst)
        {
            // This can be used for a denial of service
            // Write-Output (((((("AAAAAAAAAAAAAAAAAAAAAA"*2)*2)*2)*2)*2)*2)
            // Keep on going with that pattern, and we're generating gigabytes of strings.
            throw PSTraceSource.NewArgumentException("ast");
        }

        public object VisitUnaryExpression(UnaryExpressionAst unaryExpressionAst)
        {
            if (s_context != null)
            {
                return Compiler.GetExpressionValue(unaryExpressionAst, true, s_context, null);
            }
            else
            {
                throw PSTraceSource.NewArgumentException("ast");
            }
        }

        public object VisitConvertExpression(ConvertExpressionAst convertExpressionAst)
        {
            // at this point, we know we're safe because we checked both the type and the child,
            // so now we can just call the compiler and indicate that it's trusted (at this point)
            if (s_context != null)
            {
                return Compiler.GetExpressionValue(convertExpressionAst, true, s_context, null);
            }
            else
            {
                throw PSTraceSource.NewArgumentException("ast");
            }
        }

        public object VisitConstantExpression(ConstantExpressionAst constantExpressionAst)
        {
            return constantExpressionAst.Value;
        }

        public object VisitStringConstantExpression(StringConstantExpressionAst stringConstantExpressionAst)
        {
            return stringConstantExpressionAst.Value;
        }

        public object VisitSubExpression(SubExpressionAst subExpressionAst)
        {
            return subExpressionAst.SubExpression.Accept(this);
        }

        public object VisitUsingExpression(UsingExpressionAst usingExpressionAst)
        {
            // $using:true should be safe - it's silly to write that, but not harmful.
            return usingExpressionAst.SubExpression.Accept(this);
        }

        public object VisitVariableExpression(VariableExpressionAst variableExpressionAst)
        {
            // There are earlier checks to be sure that we are not using unreferenced variables
            // this ensures that we only use what was declared in the param block
            // other variables such as true/false/args etc have been already vetted
            string name = variableExpressionAst.VariablePath.UnqualifiedPath;
            if (variableExpressionAst.IsConstantVariable())
            {
                if (name.Equals(SpecialVariables.True, StringComparison.OrdinalIgnoreCase))
                    return true;

                if (name.Equals(SpecialVariables.False, StringComparison.OrdinalIgnoreCase))
                    return false;

                Diagnostics.Assert(name.Equals(SpecialVariables.Null, StringComparison.OrdinalIgnoreCase), "Unexpected constant variable");
                return null;
            }

            if (name.Equals(SpecialVariables.PSScriptRoot, StringComparison.OrdinalIgnoreCase))
            {
                var scriptFileName = variableExpressionAst.Extent.File;
                if (scriptFileName == null)
                    return null;

                return Path.GetDirectoryName(scriptFileName);
            }

            if (s_context != null)
            {
                return VariableOps.GetVariableValue(variableExpressionAst.VariablePath, s_context, variableExpressionAst);
            }

            throw PSTraceSource.NewArgumentException("ast");
        }

        public object VisitTypeExpression(TypeExpressionAst typeExpressionAst)
        {
            // Type expressions are not safe as they allow fingerprinting by providing
            // a set of types, you can inspect the types in the AppDomain implying which assemblies are in use
            // and their version
            throw PSTraceSource.NewArgumentException("ast");
        }

        public object VisitMemberExpression(MemberExpressionAst memberExpressionAst)
        {
            throw PSTraceSource.NewArgumentException("ast");
        }

        public object VisitArrayExpression(ArrayExpressionAst arrayExpressionAst)
        {
            // An Array expression *may* be safe, if its components are safe
            var arrayExpressionAstResult = (object[])arrayExpressionAst.SubExpression.Accept(this);
            return arrayExpressionAstResult;
        }

        public object VisitArrayLiteral(ArrayLiteralAst arrayLiteralAst)
        {
            // An array literal is safe
            ArrayList arrayElements = new ArrayList();
            foreach (var element in arrayLiteralAst.Elements)
            {
                arrayElements.Add(element.Accept(this));
            }

            return arrayElements.ToArray();
        }

        public object VisitHashtable(HashtableAst hashtableAst)
        {
            Hashtable hashtable = new Hashtable(StringComparer.CurrentCultureIgnoreCase);
            foreach (var pair in hashtableAst.KeyValuePairs)
            {
                var key = pair.Item1.Accept(this);
                var value = pair.Item2.Accept(this);
                hashtable.Add(key, value);
            }

            return hashtable;
        }

        public object VisitScriptBlockExpression(ScriptBlockExpressionAst scriptBlockExpressionAst)
        {
            return ScriptBlock.Create(scriptBlockExpressionAst.Extent.Text);
        }

        public object VisitParenExpression(ParenExpressionAst parenExpressionAst)
        {
            return parenExpressionAst.Pipeline.Accept(this);
        }
    }
}
