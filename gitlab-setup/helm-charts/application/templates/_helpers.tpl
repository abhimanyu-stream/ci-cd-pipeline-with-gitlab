{{/*
Expand the name of the chart.
*/}}
{{- define "spring-boot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "spring-boot.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "spring-boot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "spring-boot.labels" -}}
helm.sh/chart: {{ include "spring-boot.chart" . }}
{{ include "spring-boot.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "spring-boot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spring-boot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "spring-boot.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "spring-boot.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create environment variables for the application
*/}}
{{- define "spring-boot.env" -}}
- name: SPRING_PROFILES_ACTIVE
  value: {{ .Values.config.springProfiles | quote }}
- name: JAVA_OPTS
  value: {{ .Values.config.javaOpts | quote }}
{{- if .Values.database.mysql.enabled }}
- name: SPRING_DATASOURCE_URL
  value: jdbc:mysql://{{ .Values.database.mysql.host }}:{{ .Values.database.mysql.port }}/{{ .Values.database.mysql.database }}
{{- if .Values.database.mysql.existingSecret }}
- name: SPRING_DATASOURCE_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.mysql.existingSecret }}
      key: mysql-username
- name: SPRING_DATASOURCE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.mysql.existingSecret }}
      key: mysql-password
{{- else }}
- name: SPRING_DATASOURCE_USERNAME
  value: {{ .Values.database.mysql.username | quote }}
- name: SPRING_DATASOURCE_PASSWORD
  value: {{ .Values.database.mysql.password | quote }}
{{- end }}
{{- end }}
{{- if .Values.database.mongodb.enabled }}
- name: SPRING_DATA_MONGODB_HOST
  value: {{ .Values.database.mongodb.host | quote }}
- name: SPRING_DATA_MONGODB_PORT
  value: {{ .Values.database.mongodb.port | quote }}
- name: SPRING_DATA_MONGODB_DATABASE
  value: {{ .Values.database.mongodb.database | quote }}
{{- if .Values.database.mongodb.existingSecret }}
- name: SPRING_DATA_MONGODB_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.mongodb.existingSecret }}
      key: mongodb-username
- name: SPRING_DATA_MONGODB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.mongodb.existingSecret }}
      key: mongodb-password
{{- else }}
- name: SPRING_DATA_MONGODB_USERNAME
  value: {{ .Values.database.mongodb.username | quote }}
- name: SPRING_DATA_MONGODB_PASSWORD
  value: {{ .Values.database.mongodb.password | quote }}
{{- end }}
{{- end }}
{{- if .Values.logging.elk.enabled }}
- name: LOGGING_ELASTICSEARCH_HOST
  value: {{ .Values.logging.elk.host | quote }}
- name: LOGGING_ELASTICSEARCH_PORT
  value: {{ .Values.logging.elk.port | quote }}
{{- end }}
{{- range $key, $value := .Values.config.properties }}
- name: {{ $key | upper | replace "." "_" }}
  value: {{ $value | quote }}
{{- end }}
{{- end }} 