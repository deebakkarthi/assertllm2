import MutationOp
import copy
import pyverilog.vparser.ast as vast
import random
from random import randint


def _perturb_intconst_value(value_str):
    """Return a nearby, different value string for an IntConst, preserving format."""
    s = str(value_str)

    if "'" in s:
        parts = s.split("'", 1)
        width_str = parts[0].strip()
        literal = parts[1]
        if not literal:
            return s

        width = int(width_str) if width_str.isdigit() else None
        base_ch = literal[0].lower()
        digits = literal[1:].replace("_", "")

        try:
            if base_ch == "b":
                old_val = int(digits, 2) if digits else 0
            elif base_ch == "h":
                old_val = int(digits, 16) if digits else 0
            elif base_ch == "o":
                old_val = int(digits, 8) if digits else 0
            elif base_ch == "d":
                old_val = int(digits, 10) if digits else 0
            else:
                return s
        except ValueError:
            return s

        max_val = (1 << width) - 1 if width and width > 0 else max(old_val * 2, 7)
        delta = random.choice([-1, 1, 2, -2])
        new_val = old_val + delta
        new_val = max(0, min(new_val, max_val))
        if new_val == old_val:
            new_val = (old_val + 1) & max_val if width else old_val + 1

        if base_ch == "b":
            fmt_digits = bin(new_val)[2:].zfill(width or len(digits))
        elif base_ch == "h":
            fmt_digits = hex(new_val)[2:].zfill(len(digits) or 1)
        elif base_ch == "o":
            fmt_digits = oct(new_val)[2:].zfill(len(digits) or 1)
        else:
            fmt_digits = str(new_val)

        return f"{width_str}'{literal[0]}{fmt_digits}"

    try:
        old_val = int(s)
    except (ValueError, TypeError):
        return s

    delta = random.choice([-1, 1, 2, -2])
    new_val = max(0, old_val + delta)
    if new_val == old_val:
        new_val = old_val + 1
    return str(new_val)


class MutationOperators(MutationOp.MutationOp):
    def __init__(self, name, symbol, function):
        self.name = name
        self.symbol = symbol
        self.function = function
        self.mutationop = MutationOp.MutationOp(None, None, None)

    def _get_signal_range(self, root, name):
        """
        Return (msb, lsb) as ints for signal 'name', searching whole AST.
        Supports common Decl and Ioport styles.
        """
        def width_from_node(n):
            w = getattr(n, "width", None)
            if w is None:
                return None
            ints = [c for c in w.children() if c is not None and c.__class__.__name__ == "IntConst"]
            if len(ints) >= 2:
                return int(ints[0].value), int(ints[1].value)
            return None

        def dfs(n):
            if n is None:
                return None

            # Direct named decl nodes (Wire/Reg/Input/Output often have .name)
            if getattr(n, "name", None) == name:
                r = width_from_node(n)
                if r is not None:
                    return r

            # Ports: Ioport -> Input/Output -> width
            if n.__class__.__name__ == "Ioport":
                for ch in n.children():
                    if ch is None:
                        continue
                    if getattr(ch, "name", None) == name:
                        r = width_from_node(ch)
                        if r is not None:
                            return r

            for ch in n.children():
                r = dfs(ch)
                if r is not None:
                    return r
            return None

        return dfs(root)


    def DMO(self, ast, pointer_id, new_IntConst_node):
        if ast.node_id == pointer_id:
            for child in ast.children():
                if child.__class__.__name__ == "IntConst":
                    self.mutationop.replace_with_node(ast, child.node_id, new_IntConst_node)
        for child in ast.children():
            if child is not None:
                self.DMO(child, pointer_id, new_IntConst_node)
        return ast

    def DMS(self, ast, srl_id, new_IntConst_node):
        if ast.node_id == srl_id:
            for child in ast.children():
                if child.__class__.__name__ == "IntConst":
                    self.mutationop.replace_with_node(ast, child.node_id, new_IntConst_node)
        for child in ast.children():
            if child is not None:
                self.DMS(child, srl_id, new_IntConst_node)
        return ast
    
    def DMI(self, ast, partselect_id):
        if ast.node_id == partselect_id:
            for child in ast.children():
                if child.__class__.__name__ == "IntConst":
                    old_val = int(child.value)
                    if old_val <= 0:
                        continue
                    self.mutationop.replace_with_node(
                        ast, child.node_id, vast.IntConst(old_val - 1))
        for child in ast.children():
            if child is not None:
                self.DMI(child, partselect_id)
        return ast
    
    def get_dcl_width(self, ast):
        for child in ast.children():
            if child.__class__.__name__ == "Decl":
                for next_child in child.children():
                    if next_child.__class__.__name__ == "Width":
                        for next_next_child in next_child.children():
                            if next_next_child.__class__.__name__ == "IntConst":
                                return next_next_child.value
            else:
                self.get_dcl_width(child)
        pass
    
    # def DIE(self, ast, partselect_id):
    #     if ast.node_id == partselect_id:
    #         for child in ast.children():
    #             if child.__class__.__name__ == "IntConst":
    #                 self.mutationop.replace_with_node(ast, child.node_id, self.get_dcl_width(child) - vast.IntConst(int(child.value)))
    #     for child in ast.children():
    #         if child is not None:
    #             self.DIE(child, partselect_id)
    #     return ast

    def DIE(self, ast, partselect_id):
        if ast.node_id == partselect_id and ast.__class__.__name__ == "Partselect":
            # 你必须在 main 里先设置：Mutation_operator._root = <root AST>
            if not hasattr(self, "_root") or self._root is None:
                raise RuntimeError("DIE requires self._root to be set (Mutation_operator._root = ast_root)")

            # 取被切片变量名：count[23:16] -> "count"
            var = getattr(ast, "var", None)
            if var is None or var.__class__.__name__ != "Identifier":
                raise RuntimeError("DIE: Partselect.var is not an Identifier (only simple signal supported)")
            varname = var.name

            # 只支持端点是 IntConst 的 partselect（你现在的 repo 也主要这么用）
            ints = [c for c in ast.children() if c is not None and c.__class__.__name__ == "IntConst"]
            if len(ints) < 2:
                raise RuntimeError("DIE: Partselect does not contain two IntConst endpoints")
            old_msb = int(ints[0].value)
            old_lsb = int(ints[1].value)

            # 找到这个信号自己的声明范围（不是随便一个 Width）
            sig_rng = self._get_signal_range(self._root, varname)
            if sig_rng is None:
                raise RuntimeError(f"DIE: cannot find declared width for signal '{varname}'")
            sig_msb, sig_lsb = sig_rng
            hi = max(sig_msb, sig_lsb)
            lo = min(sig_msb, sig_lsb)

            # 镜像映射：mirror(i) = hi + lo - i
            def mirror(i):
                return hi + lo - i

            new_msb = mirror(old_lsb)
            new_lsb = mirror(old_msb)

            # Guard：保持 slice 位宽不变
            old_w = abs(old_msb - old_lsb) + 1
            new_w = abs(new_msb - new_lsb) + 1
            if old_w != new_w:
                raise RuntimeError(f"DIE width changed unexpectedly: {old_w} -> {new_w}")

            # Guard：不越界（必须落在 declared range 内）
            if not (lo <= new_msb <= hi and lo <= new_lsb <= hi):
                raise RuntimeError(f"DIE produced out-of-range indices: [{new_msb}:{new_lsb}] not in [{hi}:{lo}]")

            # exchange
            self.mutationop.replace_with_node(ast, ints[0].node_id, vast.IntConst(str(new_msb)))
            self.mutationop.replace_with_node(ast, ints[1].node_id, vast.IntConst(str(new_lsb)))

            return ast  # prune

        for child in ast.children():
            if child is not None:
                self.DIE(child, partselect_id)
        return ast

    ######Communication######
    def CMA(self, ast, function_id):
        if ast.node_id == function_id:
            for child in ast.children():
                if child.__class__.__name__ == "ParamArg":
                    for next_child in child.children():
                        if next_child.__class__.__name__ == "IntConst":
                            new_val = _perturb_intconst_value(next_child.value)
                            self.mutationop.replace_with_node(ast, next_child.node_id, vast.IntConst(new_val))
        for child in ast.children():
            if child is not None:
                self.CMA(child, function_id)
        return ast


    def CGA(self, ast, block_id):
        if ast.node_id == block_id:
            for child in ast.children():
                if child.__class__.__name__ == "NonblockingSubstitution" or child.__class__.__name__ == "BlockingSubstitution":
                    new_node = copy.deepcopy(child)
                    for new_ndoe_child in new_node.children():
                        if new_ndoe_child.__class__.__name__ == "Rvalue":
                            for next_new_node_child in new_ndoe_child.children():
                                if next_new_node_child.__class__.__name__ == "IntConst":
                                    next_new_node_child.value = _perturb_intconst_value(next_new_node_child.value)
                                    self.mutationop.insert_stmt_node(ast, new_node, block_id)
        for child in ast.children():
            if child is not None:
                self.CGA(child, block_id)
        return ast
    
    def CRV(self, ast, if_id):
        if ast.node_id == if_id:
            for child in ast.children():
                if child.__class__.__name__ == "Identifier" and "valid" in child.name:
                    self.mutationop.replace_with_node(ast, child.node_id, vast.IntConst(1))
        for child in ast.children():
            if child is not None:
                self.CRV(child, if_id)
        return ast
    
    def CMP(self, ast, instance_id):
        if ast.node_id == instance_id:
            candidates = []
            for child in ast.children():
                if child.__class__.__name__ == "ParamArg":
                    for next_child in child.children():
                        if next_child.__class__.__name__ == "IntConst":
                            candidates.append(next_child)
            if candidates:
                victim = random.choice(candidates)
                old_val = int(victim.value)
                # Perturb by +/- small amount to stay near valid range
                delta = random.choice([-2, -1, 1, 2])
                new_val = max(1, old_val + delta)
                self.mutationop.replace_with_node(
                    ast, victim.node_id, vast.IntConst(new_val))
        for child in ast.children():
            if child is not None:
                self.CMP(child, instance_id)
        return ast

        
    def CDP(self, ast, instance_id):
        if ast.node_id == instance_id:
            port_args = [child for child in ast.children()
                         if child is not None and child.__class__.__name__ == "PortArg"]
            if port_args:
                victim = random.choice(port_args)
                self.mutationop.replace_with_node(ast, victim.node_id, None)
        for child in ast.children():
            if child is not None:
                self.CDP(child, instance_id)
        return ast
    ######Timing######
    def TAA(self, ast, block_id):
        if ast.node_id == block_id:
            for child in ast.children():
                if child.__class__.__name__ == "NonblockingSubstitution" or child.__class__.__name__ == "BlockingSubstitution":
                    new_node = copy.deepcopy(child)
                    for new_ndoe_child in new_node.children():
                        if new_ndoe_child.__class__.__name__ == "Rvalue":
                            for next_new_node_child in new_ndoe_child.children():
                                if next_new_node_child.__class__.__name__ == "Identifier":
                                    # next_new_node_child.value = randint(1,100)
                                    self.mutationop.insert_stmt_node(ast, new_node, block_id)
        for child in ast.children():
            if child is not None:
                self.TAA(child, block_id)
        return ast

    def TMD(self, ast, delay_id):
        if ast.node_id == delay_id:
            for child in ast.children():
                if child.__class__.__name__ == "IntConst":
                    new_node = copy.deepcopy(child)
                    new_node.value = _perturb_intconst_value(child.value)
                    self.mutationop.replace_with_node(ast, child.node_id, new_node)
        for child in ast.children():
            if child is not None:
                self.TMD(child, delay_id)
        return ast


    def TRA(self, ast, always_id):
        self.mutationop.delete_node(ast, always_id)
        return ast
    

    ######Semantic######
    def SRC(self, ast, case_id):
        self.mutationop.delete_node(ast, case_id)
        return ast
    
   
    def SRI(self, ast, if_id):
        self.mutationop.delete_node(ast, if_id)
        return ast
    
    ###SRE is same with SRI
    def SRE(self, ast, else_id):
        pass
    
    def SME_operator(self, ast, block_id, replace_node_id):
        if ast.node_id == block_id:
            for child in ast.children():
                if child.__class__.__name__ == "NonblockingSubstitution" or child.__class__.__name__ == "BlockingSubstitution":
                    for new_ndoe_child in child.children():
                        if new_ndoe_child.__class__.__name__ == "Rvalue":
                            for next_new_node_child in new_ndoe_child.children():
                                if next_new_node_child.__class__.__name__ == "Plus":
                                    replace_node =copy.deepcopy(self.mutationop.get_node_from_ast(ast, replace_node_id))
                                    # print(replace_node.__class__.__name__)
                                    self.mutationop.replace_with_node(next_new_node_child, next_new_node_child.node_id, replace_node)
        for child in ast.children():
            if child is not None:
                self.SME_operator(child, block_id, replace_node_id)
        return ast
        
    def SME_constant(self, ast, block_id):
        if ast.node_id == block_id:
            for child in ast.children():
                if child.__class__.__name__ == "NonblockingSubstitution" or child.__class__.__name__ == "BlockingSubstitution":
                    for new_ndoe_child in child.children():
                        if new_ndoe_child.__class__.__name__ == "Rvalue":
                            for next_new_node_child in new_ndoe_child.children():
                                if next_new_node_child.__class__.__name__ == "IntConst":
                                    next_new_node_child.value = _perturb_intconst_value(next_new_node_child.value)
        for child in ast.children():
            if child is not None:
                self.SME_constant(child, block_id)
        return ast

    def SRA(self, ast, assignment_id):
        self.mutationop.delete_node(ast, assignment_id)
        return ast

    def SRR(self, ast, reg_id):
        self.mutationop.delete_node(ast, reg_id)
        return ast

    def SRW(self, ast, wire_id):
        self.mutationop.delete_node(ast, wire_id)
        return ast

    def CMC(self, ast, cond_id, mode):
        """
        Ternary Condition Mutation: sel ? a : b
        mode 0: replace with true branch  (-> a)
        mode 1: replace with false branch (-> b)
        mode 2: swap branches             (-> sel ? b : a)
        Requires self._root to be set.
        """
        if not hasattr(self, "_root") or self._root is None:
            raise RuntimeError("CMC requires self._root to be set")

        target = [None]
        def _find(n):
            if n is None or target[0] is not None:
                return
            if n.node_id == cond_id and n.__class__.__name__ == "Cond":
                target[0] = n
                return
            for ch in n.children():
                _find(ch)
        _find(ast)

        node = target[0]
        if node is None:
            raise RuntimeError("CMC: Cond node not found")

        true_val = node.true_value
        false_val = node.false_value
        if true_val is None or false_val is None:
            raise RuntimeError("CMC: Cond node missing true/false branches")

        if mode == 0:
            self.mutationop.replace_with_node(
                self._root, cond_id, copy.deepcopy(true_val))
        elif mode == 1:
            self.mutationop.replace_with_node(
                self._root, cond_id, copy.deepcopy(false_val))
        elif mode == 2:
            old_true = copy.deepcopy(true_val)
            old_false = copy.deepcopy(false_val)
            node.true_value = old_false
            node.false_value = old_true
        return ast
    
