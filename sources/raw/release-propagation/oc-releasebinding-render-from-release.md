---
resource: https://github.com/openchoreo/openchoreo/blob/5336791f421b3efb79603b09b8ce0c98e8ef077d/internal/controller/releasebinding/controller.go
fetched: 2026-11-16
fetch_note: "git clone --depth 1 --branch v1.3.3, openchoreo/openchoreo@5336791f421b3efb79603b09b8ce0c98e8ef077d"
---

<!-- src/oc/internal/controller/releasebinding/controller.go lines 1131,1160 -->

```

func buildComponentTypeFromRelease(componentRelease *openchoreov1alpha1.ComponentRelease) *openchoreov1alpha1.ComponentType {
	return &openchoreov1alpha1.ComponentType{
		ObjectMeta: metav1.ObjectMeta{
			// Name identifies the ComponentType in post-render validation error messages,
			// so use the frozen reference name rather than a placeholder.
			Name:      componentRelease.Spec.ComponentType.Name,
			Namespace: componentRelease.Namespace,
		},
		Spec: componentRelease.Spec.ComponentType.Spec,
	}
}

func buildTraitsFromRelease(componentRelease *openchoreov1alpha1.ComponentRelease) []openchoreov1alpha1.Trait {
	if len(componentRelease.Spec.Traits) == 0 {
		return nil
	}

	traits := make([]openchoreov1alpha1.Trait, 0, len(componentRelease.Spec.Traits))
	for _, rt := range componentRelease.Spec.Traits {
		traits = append(traits, openchoreov1alpha1.Trait{
			TypeMeta: metav1.TypeMeta{
				Kind:       string(rt.Kind),
				APIVersion: openchoreov1alpha1.GroupVersion.String(),
			},
			ObjectMeta: metav1.ObjectMeta{
				Name:      rt.Name,
				Namespace: componentRelease.Namespace,
			},
			Spec: rt.Spec,
```
