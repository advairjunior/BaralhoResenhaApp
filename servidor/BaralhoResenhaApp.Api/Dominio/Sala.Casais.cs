namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Casais em Jogo: um do casal responde a verdade sobre si, o outro tenta
/// adivinhar. Quem respondeu a verdade julga; se o palpite errou, o
/// palpiteiro bebe.
/// </summary>
public sealed partial class Sala
{
    internal const int TamanhoMaximoDaResposta = 80;

    // Quantas vezes cada um já chutou: o casal e o palpiteiro vão se revezando.
    private readonly Dictionary<Guid, int> _palpitesDados = [];

    public void DefinirPar(string token, Guid? parId)
    {
        lock (_trinco)
        {
            var eu = Reconhecer(token);
            if (parId == eu.Id)
                throw new AcaoNaoPermitidaException("Escolha outra pessoa como seu par.");
            var par = parId is null
                ? null
                : _jogadores.FirstOrDefault(j => j.Id == parId)
                    ?? throw new AcaoNaoPermitidaException("Essa pessoa não está na sala.");
            DesfazerCasal(eu);
            if (par is not null)
            {
                DesfazerCasal(par);
                eu.ParId = par.Id;
                par.ParId = eu.Id;
            }
            Tocar();
        }
    }

    public void Julgar(string token, int numeroDaRodada, bool acertou)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Revelada) return;
            var rodada = Rodada!;
            if (rodada.Carta.Modo != ModoDeJogo.CasaisEmJogo)
                throw new AcaoNaoPermitidaException("Só vale nas cartas de Casais em Jogo.");
            if (jogador.Id != rodada.Alvo)
                throw new AcaoNaoPermitidaException("Quem julga é quem respondeu a verdade.");
            if (rodada.Acertou is not null) return;

            rodada.Acertou = acertou;
            var palpiteiro = _jogadores.FirstOrDefault(j => j.Id == rodada.Palpiteiro);
            if (palpiteiro is not null)
            {
                if (acertou)
                {
                    palpiteiro.Estatisticas.Acertos++;
                }
                else
                {
                    palpiteiro.Estatisticas.Erros++;
                    Pegar(palpiteiro);
                    rodada.Revelacao = rodada.Revelacao! with { Perderam = [palpiteiro.Id] };
                }
            }
            Tocar();
        }
    }

    /// <summary>Casais com os dois na sala, cada casal uma vez.</summary>
    internal List<(Jogador Um, Jogador Outro)> Casais() =>
        _jogadores
            .Where(j => j.ParId is not null)
            .Select(j => (Um: j, Outro: _jogadores.FirstOrDefault(p => p.Id == j.ParId)))
            .Where(casal => casal.Outro is not null && casal.Um.Id.CompareTo(casal.Outro.Id) < 0)
            .Select(casal => (casal.Um, casal.Outro!))
            .ToList();

    private (Jogador Palpiteiro, Jogador Alvo) EscolherCasal()
    {
        int Palpites(Jogador jogador) => _palpitesDados.GetValueOrDefault(jogador.Id);
        var casais = Casais();
        var menos = casais.Min(c => Palpites(c.Um) + Palpites(c.Outro));
        var candidatos = casais.Where(c => Palpites(c.Um) + Palpites(c.Outro) == menos).ToList();
        var (um, outro) = candidatos[_sorteio.Next(candidatos.Count)];
        var umChuta = Palpites(um) != Palpites(outro) ? Palpites(um) < Palpites(outro) : _sorteio.Next(2) == 0;
        var (palpiteiro, alvo) = umChuta ? (um, outro) : (outro, um);
        _palpitesDados[palpiteiro.Id] = Palpites(palpiteiro) + 1;
        return (palpiteiro, alvo);
    }

    private string ValidarRespostaDoCasal(Rodada rodada, Jogador jogador, string resposta)
    {
        if (jogador.Id != rodada.Palpiteiro && jogador.Id != rodada.Alvo)
            throw new AcaoNaoPermitidaException("Essa carta é do casal: só os dois respondem.");
        var limpa = (resposta ?? string.Empty).Trim();
        if (limpa.Length == 0)
            throw new AcaoNaoPermitidaException("Escreva sua resposta.");
        if (limpa.Length > TamanhoMaximoDaResposta)
            throw new AcaoNaoPermitidaException($"Responda com até {TamanhoMaximoDaResposta} letras.");
        return limpa;
    }

    private static bool CasalRespondeu(Rodada rodada) =>
        rodada.Respostas.ContainsKey(rodada.Palpiteiro!.Value) && rodada.Respostas.ContainsKey(rodada.Alvo!.Value);

    private void DesfazerCasal(Jogador jogador)
    {
        if (jogador.ParId is null) return;
        var par = _jogadores.FirstOrDefault(j => j.Id == jogador.ParId);
        if (par is not null) par.ParId = null;
        jogador.ParId = null;
    }
}
