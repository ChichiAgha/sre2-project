{{- define "techbleat.name" -}}
techbleat-bank
{{- end -}}

{{- define "techbleat.namespace" -}}
{{- .Values.namespace.name -}}
{{- end -}}

{{- define "techbleat.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "techbleat.name" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "techbleat.labels" -}}
app.kubernetes.io/name: {{ include "techbleat.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ .Values.labels.app }}
version: {{ .Values.labels.version }}
environment: {{ .Values.global.environment }}
{{- end -}}

{{- define "techbleat.selectorLabels" -}}
app.kubernetes.io/name: {{ include "techbleat.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
