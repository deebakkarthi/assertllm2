from assertbench.methods.base import MethodBundle


METHOD_REGISTRY = {
    "plain_prompt": "assertbench.methods.plain_prompt.bundle:PlainPromptBundle",
}


def get_method_bundle(method_id: str) -> MethodBundle:
    if method_id not in METHOD_REGISTRY:
        known = ", ".join(sorted(METHOD_REGISTRY))
        raise ValueError(f"Unknown method '{method_id}'. Available: {known}")
    module_path, class_name = METHOD_REGISTRY[method_id].split(":")
    module = __import__(module_path, fromlist=[class_name])
    return getattr(module, class_name)()
