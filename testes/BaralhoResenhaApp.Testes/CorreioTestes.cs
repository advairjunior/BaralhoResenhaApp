using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

public sealed class CorreioTestes
{
    private static readonly Carta Pergunta =
        new("co-1", ModoDeJogo.Correio, NivelDaCarta.Leve, "O apelido de {jogador} num reality show.");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Alvo => Todos.Single(j => j.Id == Sala.Rodada!.Alvo);
        public List<Jogador> Escritores => Todos.Where(j => j.Id != Sala.Rodada!.Alvo).ToList();
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar(int seed = 4, int pessoas = 4)
    {
        var sala = new Sala("ABCD", new Baralho([Pergunta]), new Random(seed));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda", "Edu" }.Take(pessoas)
            .Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Correio], true));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void QuemEstaNaFotoFicaDeForaENaoEscreve()
    {
        var mesa = Montar();

        Assert.Equal($"O apelido de {mesa.Alvo.Nome} num reality show.", mesa.Sala.Rodada!.Texto);
        Assert.True(mesa.Sala.Rodada.PedeResposta);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Alvo.Token, mesa.Rodada, "eu mesmo"));
        Assert.Equal("Essa é sobre você: aguarde a turma escrever.", erro.Message);
    }

    [Fact]
    public void BilheteEhCurtoENaoPodeSerVazio()
    {
        var mesa = Montar();
        var escritor = mesa.Escritores[0];

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Responder(escritor.Token, mesa.Rodada, "   "));
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(escritor.Token, mesa.Rodada, new string('a', Sala.TamanhoDoBilhete + 1)));
        Assert.Equal($"Bilhete curto: até {Sala.TamanhoDoBilhete} letras.", erro.Message);

        // Emoji conta como uma letra só; espaço sobrando é limpo.
        mesa.Sala.Responder(escritor.Token, mesa.Rodada, "  Rei   do   😂😂  ");
        Assert.Equal("Rei do 😂😂", mesa.Sala.Rodada!.Respostas[escritor.Id]);
    }

    [Fact]
    public void QuandoTodosEscrevemRevelaOsBilhetesSemDizerQuemEscreveu()
    {
        var mesa = Montar();
        var textos = new[] { "Rainha do drama", "Tio do pavê", "Sumido(a)" };
        foreach (var (escritor, texto) in mesa.Escritores.Zip(textos))
        {
            // Antes da revelação, ninguém vê bilhete de ninguém, nem o alvo.
            Assert.Null(mesa.Sala.Visao(mesa.Alvo.Token).Rodada!.Revelacao);
            mesa.Sala.Responder(escritor.Token, mesa.Rodada, texto);
        }

        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        var revelacao = mesa.Sala.Visao(mesa.Alvo.Token).Rodada!.Revelacao!;
        Assert.Equal(textos.Order(), revelacao.Bilhetes.Order());
        Assert.Empty(revelacao.JaFizeram);
        Assert.Empty(revelacao.Votos);
        Assert.Empty(revelacao.Perderam);
        Assert.Equal([mesa.Alvo.Id], revelacao.Escolhidos);
        Assert.All(mesa.Todos, j => Assert.Equal(0, j.Pontos));
    }

    [Fact]
    public void AOrdemDosBilhetesNaoEntregaQuemEscreveuPrimeiro()
    {
        var ordens = new HashSet<string>();
        for (var seed = 0; seed < 12; seed++)
        {
            var mesa = Montar(seed, pessoas: 5);
            foreach (var (escritor, i) in mesa.Escritores.Select((e, i) => (e, i)))
                mesa.Sala.Responder(escritor.Token, mesa.Rodada, $"bilhete {i}");
            ordens.Add(string.Join("|", mesa.Sala.Rodada!.Revelacao!.Bilhetes));
        }

        Assert.True(ordens.Count > 1, "Os bilhetes saíram sempre na ordem em que foram escritos.");
    }

    [Fact]
    public void RevelarAntesPedePeloMenosDoisBilhetesParaSeguirAnonimo()
    {
        var mesa = Montar();
        var anfitriao = mesa.Todos[0];
        mesa.Sala.Responder(mesa.Escritores[0].Token, mesa.Rodada, "Gente boa");

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Revelar(anfitriao.Token, mesa.Rodada));
        Assert.Equal("Espere pelo menos 2 bilhetes: com um só, todo mundo sabe quem escreveu.", erro.Message);

        mesa.Sala.Responder(mesa.Escritores[1].Token, mesa.Rodada, "Gente fina");
        mesa.Sala.Revelar(anfitriao.Token, mesa.Rodada);
        Assert.Equal(2, mesa.Sala.Rodada!.Revelacao!.Bilhetes.Count);
    }

    [Fact]
    public void SoQuemEstaNaFotoEscolheOBilheteFavorito()
    {
        var mesa = Montar();
        foreach (var escritor in mesa.Escritores) mesa.Sala.Responder(escritor.Token, mesa.Rodada, $"oi {escritor.Nome}");

        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.EscolherFavorito(mesa.Escritores[0].Token, mesa.Rodada, 0));
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.EscolherFavorito(mesa.Alvo.Token, mesa.Rodada, 3));

        mesa.Sala.EscolherFavorito(mesa.Alvo.Token, mesa.Rodada, 1);
        Assert.Equal(1, mesa.Sala.Visao(mesa.Escritores[0].Token).Rodada!.Favorito);
        mesa.Sala.EscolherFavorito(mesa.Alvo.Token, mesa.Rodada, 1);
        Assert.Null(mesa.Sala.Rodada!.Favorito);
    }

    [Fact]
    public void CorreioPrecisaDeQuatroPessoasParaSerAnonimo()
    {
        var baralho = new Baralho([Pergunta, new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se")]);
        var configuracao = new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.Correio, ModoDeJogo.BebaSe], true);

        for (var i = 0; i < 30; i++)
            Assert.Equal(ModoDeJogo.BebaSe, baralho.Sortear(configuracao, new HashSet<string>(), 3, false, new Random(i))!.Modo);
        Assert.Contains(Enumerable.Range(0, 30),
            i => baralho.Sortear(configuracao, new HashSet<string>(), 4, false, new Random(i))!.Modo == ModoDeJogo.Correio);
    }

    [Fact]
    public void QuemEstaNaFotoPodeTirarSelfieProMural()
    {
        var mesa = Montar();
        foreach (var escritor in mesa.Escritores) mesa.Sala.Responder(escritor.Token, mesa.Rodada, "Brabo");

        mesa.Sala.RegistrarMomento(mesa.Alvo.Token, mesa.Rodada, [0xFF, 0xD8, 0xFF]);

        Assert.Single(mesa.Sala.Visao(mesa.Alvo.Token).Momentos);
    }
}
