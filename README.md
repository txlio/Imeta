# Imeta

**Transforme seus objetivos em conquistas. Evolua um dia de cada vez.**

O Imeta é um aplicativo de organização pessoal desenvolvido com Flutter e Dart, criado para ajudar os usuários a organizar suas metas, gerenciar tarefas e acompanhar hábitos diários.

Com elementos de gamificação, como XP, níveis e conquistas, o aplicativo busca tornar o desenvolvimento pessoal mais motivador, incentivando a consistência e o acompanhamento do progresso.

## Sobre o projeto

O Imeta foi desenvolvido com o propósito de reunir ferramentas de organização pessoal em um único aplicativo, facilitando o planejamento das atividades e o acompanhamento da evolução individual.

A aplicação utiliza armazenamento local para manter os dados no dispositivo, permitindo seu uso sem depender de um servidor externo.

## Funcionalidades

- **Metas:** cadastro e acompanhamento de objetivos pessoais.
- **Tarefas:** organização e gerenciamento de atividades diárias.
- **Hábitos:** acompanhamento de hábitos e sequências de dias.
- **Sistema de XP:** pontuação por atividades realizadas.
- **Níveis:** evolução baseada na experiência acumulada.
- **Conquistas:** recompensas pelo progresso alcançado.
- **Dashboard:** resumo das informações e lembretes.
- **Progresso:** acompanhamento da evolução pessoal.
- **Armazenamento local:** persistência dos dados no dispositivo.

## Tecnologias utilizadas

- **Flutter:** framework para desenvolvimento de aplicações multiplataforma.
- **Dart:** linguagem de programação.
- **SharedPreferences:** armazenamento local de informações.
- **Git:** controle de versão.
- **GitHub:** hospedagem e gerenciamento do código-fonte.

## Requisitos para execução

Para executar o projeto, é necessário ter:

- Flutter SDK instalado e configurado.
- Git instalado.
- Visual Studio Code ou outra IDE compatível.
- Um dispositivo Android, emulador ou navegador compatível.

## Como executar o projeto

### 1. Clonar o repositório

```bash
git clone https://github.com/txlio/Imeta.git
```

### 2. Acessar a pasta do projeto

```bash
cd Imeta
```

### 3. Instalar as dependências

```bash
flutter pub get
```

### 4. Verificar o ambiente

```bash
flutter doctor
```

### 5. Executar o aplicativo

```bash
flutter run
```

Para executar no Google Chrome:

```bash
flutter run -d chrome
```

## Gerar o APK para Android

Para gerar uma versão instalável do Imeta, execute:

```bash
flutter build apk --release
```

O arquivo será gerado no seguinte caminho:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Após a compilação, o APK poderá ser transferido para um dispositivo Android compatível para instalação.

## Armazenamento de dados

O Imeta utiliza o SharedPreferences para armazenar informações localmente no dispositivo.

Os dados não são sincronizados automaticamente entre dispositivos. A desinstalação do aplicativo ou a limpeza dos dados pode resultar na perda das informações armazenadas.

## Possíveis melhorias futuras

- Implementação de backup e restauração de dados.
- Notificações locais para tarefas e hábitos.
- Relatórios mais detalhados de progresso.
- Sincronização de informações entre dispositivos.
- Aprimoramento contínuo da interface e da experiência do usuário.

## Objetivo acadêmico

O desenvolvimento do Imeta permite aplicar conhecimentos de desenvolvimento mobile, lógica de programação, gerenciamento de estado, persistência de dados e experiência do usuário.

## Autor

**Tulio Reis**

Projeto desenvolvido com Flutter e Dart.